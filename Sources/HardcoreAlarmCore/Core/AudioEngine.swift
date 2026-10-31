import Foundation
import AVFoundation

public struct SoundDefinition: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let isCustom: Bool
    
    public init(id: String, name: String, category: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isCustom = isCustom
    }
}

public final class AudioEngine: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    public static let shared = AudioEngine()
    
    private var primaryPlayer: AVAudioPlayer?
    private var backupPlayer: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var rampTimer: Timer?
    private var currentTargetVolume: Float = 1.0
    private var rampStepInterval: TimeInterval = 0.1
    private var currentRampStep: Float = 0.0
    
    // Cache for synthesized wave data
    private var soundCache: [String: Data] = [:]
    
    public let builtInSounds: [SoundDefinition] = [
        SoundDefinition(id: "emergency_siren", name: "Emergency Siren", category: "Emergency"),
        SoundDefinition(id: "industrial_klaxon", name: "Industrial Klaxon", category: "Industrial"),
        SoundDefinition(id: "electronic_warning", name: "Electronic Warning", category: "Electronic"),
        SoundDefinition(id: "loud_beep", name: "Tactical Beeping", category: "Beeps"),
        SoundDefinition(id: "mechanical_alarm", name: "Mechanical Twin-Bell", category: "Mechanical"),
        SoundDefinition(id: "nuclear_klaxon", name: "Nuclear Threat Klaxon", category: "Emergency"),
        SoundDefinition(id: "sub_bass_pulse", name: "Sub-Bass War Drum", category: "Bass Pulse")
    ]
    
    public override init() {
        super.init()
        preloadSynthesizedSounds()
    }
    
    // MARK: - Sound Preloading
    private func preloadSynthesizedSounds() {
        for sound in builtInSounds {
            if soundCache[sound.id] == nil {
                soundCache[sound.id] = generateSynthesizedWaveData(for: sound.id)
            }
        }
    }
    
    // MARK: - Alarm Playback
    public func startAlarm(
        soundId: String,
        volume: Double,
        gradual: Bool,
        rampDuration: TimeInterval,
        customAudioURL: URL? = nil,
        voiceAnnouncement: Bool = false,
        alarmTitle: String = "Wake Up"
    ) {
        stopAll()
        
        currentTargetVolume = Float(max(0.1, min(1.0, volume)))
        
        let audioData: Data?
        if let customURL = customAudioURL, let data = try? Data(contentsOf: customURL) {
            audioData = data
        } else {
            audioData = soundCache[soundId] ?? generateSynthesizedWaveData(for: soundId)
        }
        
        guard let data = audioData else {
            print("[AudioEngine] Error: Could not get audio data for \(soundId)")
            return
        }
        
        do {
            primaryPlayer = try AVAudioPlayer(data: data)
            primaryPlayer?.numberOfLoops = -1 // Infinite loop
            primaryPlayer?.prepareToPlay()
            
            if gradual && rampDuration > 0 {
                let initialVolume: Float = 0.05
                primaryPlayer?.volume = initialVolume
                primaryPlayer?.play()
                
                let steps = Float(rampDuration / rampStepInterval)
                let volumeIncrement = (currentTargetVolume - initialVolume) / max(1.0, steps)
                
                rampTimer?.invalidate()
                let timer = Timer(timeInterval: rampStepInterval, repeats: true) { [weak self] _ in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self, let player = self.primaryPlayer else {
                            return
                        }
                        if player.volume < self.currentTargetVolume {
                            player.volume = min(self.currentTargetVolume, player.volume + volumeIncrement)
                        } else {
                            self.rampTimer?.invalidate()
                            self.rampTimer = nil
                        }
                    }
                }
                RunLoop.main.add(timer, forMode: .common)
                rampTimer = timer
            } else {
                primaryPlayer?.volume = currentTargetVolume
                primaryPlayer?.play()
            }
            
            if voiceAnnouncement {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.speakAnnouncement(title: alarmTitle)
                }
            }
        } catch {
            print("[AudioEngine] Failed to initialize primary player: \(error)")
        }
    }
    
    public func startBackupAlarm(soundId: String = "nuclear_klaxon") {
        let data = soundCache[soundId] ?? generateSynthesizedWaveData(for: soundId)
        do {
            backupPlayer = try AVAudioPlayer(data: data)
            backupPlayer?.numberOfLoops = -1
            backupPlayer?.volume = 1.0
            backupPlayer?.play()
        } catch {
            print("[AudioEngine] Failed to start backup player: \(error)")
        }
    }
    
    public func previewSound(soundId: String, volume: Double = 0.8) {
        previewPlayer?.stop()
        previewPlayer = nil
        
        let data = soundCache[soundId] ?? generateSynthesizedWaveData(for: soundId)
        do {
            previewPlayer = try AVAudioPlayer(data: data)
            previewPlayer?.numberOfLoops = 0
            previewPlayer?.volume = Float(volume)
            previewPlayer?.play()
            
            // Auto stop preview after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.previewPlayer?.stop()
                self?.previewPlayer = nil
            }
        } catch {
            print("[AudioEngine] Preview failed: \(error)")
        }
    }
    
    public func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
    }
    
    public func stopAll() {
        rampTimer?.invalidate()
        rampTimer = nil
        
        primaryPlayer?.stop()
        primaryPlayer = nil
        
        backupPlayer?.stop()
        backupPlayer = nil
        
        previewPlayer?.stop()
        previewPlayer = nil
        
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - Speech Synthesis
    public func speakAnnouncement(title: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        let text = "Attention! The time is \(timeString). \(title). Wake up and complete your challenge now."
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        utterance.pitchMultiplier = 1.1
        utterance.volume = 1.0
        
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Programmatic Waveform Synthesizer
    // Synthesizes 16-bit 44.1kHz mono PCM WAV data
    private func generateSynthesizedWaveData(for soundId: String) -> Data {
        let sampleRate: Double = 44100.0
        let duration: Double = 2.0 // 2 seconds seamless loop
        let totalSamples = Int(sampleRate * duration)
        
        var samples = [Int16](repeating: 0, count: totalSamples)
        
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            var sampleVal: Double = 0.0
            
            switch soundId {
            case "emergency_siren":
                // Two-tone wail cycling between 750Hz and 1050Hz every 0.5s
                let cycle = (t.truncatingRemainder(dividingBy: 0.5)) / 0.5
                let freq = 750.0 + 300.0 * (sin(cycle * .pi * 2.0) * 0.5 + 0.5)
                let wave1 = sin(2.0 * .pi * freq * t)
                let wave2 = sin(2.0 * .pi * (freq * 1.5) * t) * 0.3
                sampleVal = (wave1 + wave2) * 0.9
                
            case "industrial_klaxon":
                // 150 Hz harsh sawtooth combined with 450 Hz dissonant harmonic bursts (0.4s on, 0.1s off)
                let pulse = (t.truncatingRemainder(dividingBy: 0.5)) < 0.38 ? 1.0 : 0.05
                let saw1 = 2.0 * (t * 150.0 - floor(t * 150.0 + 0.5))
                let saw2 = 2.0 * (t * 450.0 - floor(t * 450.0 + 0.5)) * 0.5
                sampleVal = (saw1 + saw2) * pulse * 0.9
                
            case "electronic_warning":
                // High pitch FM modulated chirp (1800Hz modulated by 12Hz)
                let mod = sin(2.0 * .pi * 12.0 * t) * 400.0
                let carrier = sin(2.0 * .pi * (1800.0 + mod) * t)
                let pulse = (t.truncatingRemainder(dividingBy: 0.25)) < 0.18 ? 1.0 : 0.0
                sampleVal = carrier * pulse * 0.95
                
            case "loud_beep":
                // Tactical triple-beep pattern (0.08s on, 0.06s off) at 2400 Hz
                let subTime = t.truncatingRemainder(dividingBy: 0.6)
                let isBeeping = (subTime < 0.08) || (subTime >= 0.14 && subTime < 0.22) || (subTime >= 0.28 && subTime < 0.36)
                let beep = sin(2.0 * .pi * 2400.0 * t)
                sampleVal = isBeeping ? beep * 0.95 : 0.0
                
            case "mechanical_alarm":
                // Twin-bell rapid ringing simulation (880 Hz + 920 Hz beating with 20Hz hammer)
                let hammer = sin(2.0 * .pi * 20.0 * t) > 0 ? 1.0 : 0.2
                let bell1 = sin(2.0 * .pi * 880.0 * t)
                let bell2 = sin(2.0 * .pi * 920.0 * t) * 0.8
                sampleVal = (bell1 + bell2) * hammer * 0.7
                
            case "nuclear_klaxon":
                // Dissonant tritone wail (440 Hz + 622 Hz) with low rumble
                let cycle = sin(2.0 * .pi * 0.8 * t) * 0.5 + 0.5
                let freqA = 440.0 + 80.0 * cycle
                let freqB = 622.0 + 110.0 * cycle
                let sub = sin(2.0 * .pi * 110.0 * t) * 0.4
                sampleVal = (sin(2.0 * .pi * freqA * t) + sin(2.0 * .pi * freqB * t) + sub) * 0.65
                
            case "sub_bass_pulse":
                // Heavy 60 Hz kick punch with 3000 Hz transient click
                let beatTime = t.truncatingRemainder(dividingBy: 0.5)
                let kickDecay = max(0.0, 1.0 - beatTime * 4.0)
                let kick = sin(2.0 * .pi * (60.0 + kickDecay * 40.0) * beatTime) * kickDecay
                let click = (beatTime < 0.01) ? sin(2.0 * .pi * 3200.0 * beatTime) : 0.0
                sampleVal = (kick * 0.9 + click * 0.4)
                
            default:
                // Default fallback beep
                sampleVal = sin(2.0 * .pi * 1000.0 * t) * 0.8
            }
            
            // Clamp and convert to 16-bit PCM
            let clamped = max(-1.0, min(1.0, sampleVal))
            samples[i] = Int16(clamped * 32767.0)
        }
        
        return createWavData(from: samples, sampleRate: Int(sampleRate))
    }
    
    private func createWavData(from samples: [Int16], sampleRate: Int) -> Data {
        var data = Data()
        
        let byteRate = sampleRate * 2 // 1 channel, 16 bits = 2 bytes per sample
        let blockAlign: Int16 = 2
        let bitsPerSample: Int16 = 16
        let subchunk2Size = samples.count * 2
        let chunkSize = 36 + subchunk2Size
        
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        var chunkSizeBytes = UInt32(chunkSize).littleEndian
        data.append(Data(bytes: &chunkSizeBytes, count: 4))
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt subchunk
        data.append(contentsOf: "fmt ".utf8)
        var subchunk1Size = UInt32(16).littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat = UInt16(1).littleEndian // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = UInt16(1).littleEndian // Mono
        data.append(Data(bytes: &numChannels, count: 2))
        var sampleRateBytes = UInt32(sampleRate).littleEndian
        data.append(Data(bytes: &sampleRateBytes, count: 4))
        var byteRateBytes = UInt32(byteRate).littleEndian
        data.append(Data(bytes: &byteRateBytes, count: 4))
        var blockAlignBytes = UInt16(blockAlign).littleEndian
        data.append(Data(bytes: &blockAlignBytes, count: 2))
        var bitsPerSampleBytes = UInt16(bitsPerSample).littleEndian
        data.append(Data(bytes: &bitsPerSampleBytes, count: 2))
        
        // data subchunk
        data.append(contentsOf: "data".utf8)
        var subchunk2SizeBytes = UInt32(subchunk2Size).littleEndian
        data.append(Data(bytes: &subchunk2SizeBytes, count: 4))
        
        // PCM samples
        samples.withUnsafeBufferPointer { buffer in
            data.append(buffer)
        }
        
        return data
    }
}

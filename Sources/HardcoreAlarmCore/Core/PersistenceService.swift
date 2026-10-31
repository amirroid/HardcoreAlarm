import Foundation

public final class PersistenceService: @unchecked Sendable {
    public static let shared = PersistenceService()
    
    private let fileManager = FileManager.default
    private let appSupportDir: URL
    private let alarmsURL: URL
    private let historyURL: URL
    private let settingsURL: URL
    
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()
    
    public init() {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let baseDir = urls.first ?? fileManager.temporaryDirectory
        self.appSupportDir = baseDir.appendingPathComponent("HardcoreAlarm", isDirectory: true)
        
        try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        
        self.alarmsURL = appSupportDir.appendingPathComponent("alarms.json")
        self.historyURL = appSupportDir.appendingPathComponent("history.json")
        self.settingsURL = appSupportDir.appendingPathComponent("settings.json")
    }
    
    // MARK: - Alarms
    public func loadAlarms() -> [Alarm] {
        guard fileManager.fileExists(atPath: alarmsURL.path) else {
            let defaults = createDefaultAlarms()
            saveAlarms(defaults)
            return defaults
        }
        do {
            let data = try Data(contentsOf: alarmsURL)
            return try decoder.decode([Alarm].self, from: data)
        } catch {
            print("[PersistenceService] Error loading alarms: \(error). Using defaults.")
            let defaults = createDefaultAlarms()
            saveAlarms(defaults)
            return defaults
        }
    }
    
    public func saveAlarms(_ alarms: [Alarm]) {
        do {
            let data = try encoder.encode(alarms)
            try data.write(to: alarmsURL, options: .atomic)
        } catch {
            print("[PersistenceService] Error saving alarms: \(error)")
        }
    }
    
    // MARK: - History
    public func loadHistory() -> [AlarmHistoryRecord] {
        guard fileManager.fileExists(atPath: historyURL.path) else {
            let initial = createInitialSampleHistory()
            saveHistory(initial)
            return initial
        }
        do {
            let data = try Data(contentsOf: historyURL)
            return try decoder.decode([AlarmHistoryRecord].self, from: data)
        } catch {
            print("[PersistenceService] Error loading history: \(error)")
            return []
        }
    }
    
    public func saveHistory(_ history: [AlarmHistoryRecord]) {
        do {
            let data = try encoder.encode(history)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            print("[PersistenceService] Error saving history: \(error)")
        }
    }
    
    public func appendHistoryRecord(_ record: AlarmHistoryRecord) {
        var current = loadHistory()
        current.insert(record, at: 0)
        // Keep up to 200 recent records
        if current.count > 200 {
            current = Array(current.prefix(200))
        }
        saveHistory(current)
    }
    
    // MARK: - Settings
    public func loadSettings() -> AppSettings {
        guard fileManager.fileExists(atPath: settingsURL.path) else {
            let defaultSettings = AppSettings()
            saveSettings(defaultSettings)
            return defaultSettings
        }
        do {
            let data = try Data(contentsOf: settingsURL)
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            print("[PersistenceService] Error loading settings: \(error)")
            return AppSettings()
        }
    }
    
    public func saveSettings(_ settings: AppSettings) {
        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            print("[PersistenceService] Error saving settings: \(error)")
        }
    }
    
    // MARK: - Defaults
    private func createDefaultAlarms() -> [Alarm] {
        [
            Alarm(
                title: "Workday Heavy Wake-Up",
                details: "Mandatory hardcore math and memory sequence. No snoozing.",
                hour: 6,
                minute: 30,
                isEnabled: true,
                repeatDays: Weekday.weekdaysOnly,
                soundId: "emergency_siren",
                volume: 1.0,
                gradualVolume: true,
                volumeRampDuration: 15.0,
                gradualSoundIntensity: true,
                voiceAnnouncementEnabled: true,
                snooze: SnoozeConfig(isEnabled: false, durationMinutes: 0, maxCount: 0, remainingCount: 0),
                backupAlarmEnabled: true,
                backupAlarmDelaySeconds: 45.0,
                backupSoundId: "nuclear_klaxon",
                challenges: AlarmPreset.hardcore.defaultChallenges,
                wakeUpVerification: WakeUpVerificationConfig(isEnabled: true, delayMinutes: 5, stagesCount: 1),
                preset: .hardcore
            ),
            Alarm(
                title: "Weekend Reset",
                details: "Gentle morning start with 2 simple math problems.",
                hour: 8,
                minute: 30,
                isEnabled: true,
                repeatDays: Weekday.weekendsOnly,
                soundId: "electronic_warning",
                volume: 0.8,
                gradualVolume: true,
                volumeRampDuration: 30.0,
                gradualSoundIntensity: false,
                voiceAnnouncementEnabled: true,
                snooze: SnoozeConfig(isEnabled: true, durationMinutes: 5, maxCount: 2, remainingCount: 2),
                backupAlarmEnabled: false,
                challenges: AlarmPreset.normal.defaultChallenges,
                wakeUpVerification: WakeUpVerificationConfig(isEnabled: false),
                preset: .normal
            ),
            Alarm(
                title: "Emergency Critical Alarm",
                details: "Full nuclear gauntlet with typing and multi-stage verification.",
                hour: 5,
                minute: 45,
                isEnabled: false,
                repeatDays: Weekday.all,
                soundId: "nuclear_klaxon",
                volume: 1.0,
                gradualVolume: false,
                volumeRampDuration: 0.0,
                gradualSoundIntensity: true,
                voiceAnnouncementEnabled: true,
                snooze: SnoozeConfig(isEnabled: false, durationMinutes: 0, maxCount: 0, remainingCount: 0),
                backupAlarmEnabled: true,
                backupAlarmDelaySeconds: 30.0,
                backupSoundId: "emergency_siren",
                challenges: AlarmPreset.extreme.defaultChallenges,
                wakeUpVerification: WakeUpVerificationConfig(isEnabled: true, delayMinutes: 4, stagesCount: 2),
                preset: .extreme
            )
        ]
    }
    
    private func createInitialSampleHistory() -> [AlarmHistoryRecord] {
        let now = Date()
        let cal = Calendar.current
        var records: [AlarmHistoryRecord] = []
        
        let daysAgo = [6, 5, 4, 3, 2, 1]
        for days in daysAgo {
            if let date = cal.date(byAdding: .day, value: -days, to: now) {
                var comp = cal.dateComponents([.year, .month, .day], from: date)
                comp.hour = 6
                comp.minute = 30
                let sched = cal.date(from: comp) ?? date
                let fired = sched.addingTimeInterval(Double.random(in: 0...2))
                let duration = Double.random(in: 35...78)
                let dismissed = fired.addingTimeInterval(duration)
                
                records.append(AlarmHistoryRecord(
                    alarmId: UUID(),
                    alarmTitle: "Workday Heavy Wake-Up",
                    scheduledTime: sched,
                    firedTime: fired,
                    dismissedTime: dismissed,
                    wasSuccessful: true,
                    wasDismissedViaChallenge: true,
                    solveDurationSeconds: duration,
                    snoozesUsed: 0,
                    mistakeCount: Int.random(in: 0...2),
                    challengesCompleted: [.math, .memory],
                    verificationStatus: .passed,
                    difficulty: .hard
                ))
            }
        }
        return records
    }
}

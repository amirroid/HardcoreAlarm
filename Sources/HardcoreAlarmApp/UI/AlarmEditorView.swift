import SwiftUI
import HardcoreAlarmCore

public struct AlarmEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @UIState private var alarm: Alarm
    @UIState private var selectedPreset: AlarmPreset
    @UIState private var isPreviewingSound: Bool = false
    
    public let onSave: (Alarm) -> Void
    
    public init(alarm: Alarm? = nil, onSave: @escaping (Alarm) -> Void) {
        let initial = alarm ?? Alarm.makePresetAlarm(preset: .hardcore)
        _alarm = UIState(initialValue: initial)
        _selectedPreset = UIState(initialValue: initial.preset)
        self.onSave = onSave
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CONFIGURE ALARM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentAmber)
                    Text(alarm.title.isEmpty ? "New Alarm" : alarm.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    AudioEngine.shared.stopPreview()
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .padding(.trailing, 12)
                
                GlowingButton(title: "Save Alarm", icon: "checkmark", style: .primary) {
                    AudioEngine.shared.stopPreview()
                    onSave(alarm)
                    dismiss()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Theme.bgSecondary)
            
            Divider()
                .background(Theme.borderSubtle)
            
            // Editor Body
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // 1. Presets Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ALARM PRESET")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(AlarmPreset.allCases) { preset in
                                Button(action: {
                                    applyPreset(preset)
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: preset.iconName)
                                            .font(.system(size: 14, weight: .bold))
                                        Text(preset.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .foregroundColor(selectedPreset == preset ? Theme.textPrimary : Theme.textMuted)
                                    .background(selectedPreset == preset ? Theme.accentAmber.opacity(0.18) : Theme.bgDeep)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedPreset == preset ? Theme.accentAmber.opacity(0.5) : Theme.borderSubtle, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Text(selectedPreset.subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                            .padding(.top, 2)
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 14)
                    
                    // 2. Time & Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TIME & SCHEDULE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        
                        // Time Pickers
                        HStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Picker("Hour", selection: $alarm.hour) {
                                    ForEach(0..<24, id: \.self) { h in
                                        Text(String(format: "%02d", h)).tag(h)
                                    }
                                }
                                .frame(width: 80)
                                
                                Text(":")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Theme.textDim)
                                
                                Picker("Minute", selection: $alarm.minute) {
                                    ForEach(0..<60, id: \.self) { m in
                                        Text(String(format: "%02d", m)).tag(m)
                                    }
                                }
                                .frame(width: 80)
                            }
                            
                            Spacer()
                            
                            Text(alarm.formattedTime)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.accentAmber)
                        }
                        
                        // Title & Details Input
                        TextField("Alarm Title", text: $alarm.title)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Theme.bgDeep)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderSubtle, lineWidth: 1))
                        
                        TextField("Note or Motivation (optional)", text: $alarm.details)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Theme.bgDeep)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderSubtle, lineWidth: 1))
                        
                        // Repeat Weekdays
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("REPEAT DAYS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                Spacer()
                                Button("Weekdays") { alarm.repeatDays = Weekday.weekdaysOnly }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Theme.accentAmber)
                                Button("Weekends") { alarm.repeatDays = Weekday.weekendsOnly }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Theme.accentAmber)
                                Button("Every Day") { alarm.repeatDays = Weekday.all }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Theme.accentAmber)
                                Button("One-Time") { alarm.repeatDays = [] }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Theme.accentRed)
                            }
                            
                            HStack(spacing: 8) {
                                ForEach(Weekday.allCases.sorted(), id: \.self) { day in
                                    let isSelected = alarm.repeatDays.contains(day)
                                    Button(action: {
                                        if isSelected {
                                            alarm.repeatDays.remove(day)
                                        } else {
                                            alarm.repeatDays.insert(day)
                                        }
                                    }) {
                                        Text(day.shortName)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textDim)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Theme.accentAmber.opacity(0.2) : Theme.bgDeep)
                                            .cornerRadius(6)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? Theme.accentAmber.opacity(0.4) : Theme.borderSubtle, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 14)
                    
                    // 3. Audio & Volume Ramp
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AUDIO & VOLUME INTENSITY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        
                        HStack(spacing: 12) {
                            Picker("Alarm Sound", selection: $alarm.soundId) {
                                ForEach(AudioEngine.shared.builtInSounds) { sound in
                                    Text("\(sound.name) (\(sound.category))").tag(sound.id)
                                }
                            }
                            
                            Button(action: toggleSoundPreview) {
                                HStack(spacing: 5) {
                                    Image(systemName: isPreviewingSound ? "stop.fill" : "play.fill")
                                    Text(isPreviewingSound ? "Stop" : "Preview")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isPreviewingSound ? Theme.accentRed : Theme.accentAmber)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.bgDeep)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderSubtle, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Volume Slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Maximum Volume")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Text("\(Int(alarm.volume * 100))%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            Slider(value: $alarm.volume, in: 0.1...1.0)
                                .tint(Theme.accentAmber)
                        }
                        
                        // Gradual Volume Ramp
                        Toggle("Gradually Ramp Volume", isOn: $alarm.gradualVolume)
                            .toggleStyle(.switch)
                        
                        if alarm.gradualVolume {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Ramp Duration")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    Text("\(Int(alarm.volumeRampDuration))s")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                Slider(value: $alarm.volumeRampDuration, in: 5...120, step: 5)
                                    .tint(Theme.accentAmber)
                            }
                        }
                        
                        Toggle("Voice Wake-Up Announcement", isOn: $alarm.voiceAnnouncementEnabled)
                            .toggleStyle(.switch)
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 14)
                    
                    // 4. Hardcore Challenges Chain
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("HARDCORE CHALLENGES")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.accentAmber)
                                Text("Mandatory gauntlet to dismiss alarm")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textMuted)
                            }
                            
                            Spacer()
                            
                            Menu {
                                Button("Add Math Challenge") {
                                    alarm.challenges.append(ChallengeConfig.defaultMath)
                                }
                                Button("Add Memory Sequence") {
                                    alarm.challenges.append(ChallengeConfig.defaultMemory)
                                }
                                Button("Add Hardcore Typing") {
                                    alarm.challenges.append(ChallengeConfig.defaultTyping)
                                }
                                Button("Add Pattern Recognition") {
                                    alarm.challenges.append(ChallengeConfig.defaultPattern)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Add Challenge")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.accentAmber)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.bgDeep)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderSubtle, lineWidth: 1))
                            }
                            .menuStyle(.borderlessButton)
                        }
                        
                        if alarm.challenges.isEmpty {
                            Text("No challenges added. Alarm can be dismissed immediately.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.accentRed)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(alarm.challenges.enumerated()), id: \.element.id) { index, challenge in
                                ChallengeRowConfigView(
                                    index: index + 1,
                                    challenge: Binding(
                                        get: { alarm.challenges[index] },
                                        set: { alarm.challenges[index] = $0 }
                                    ),
                                    onDelete: {
                                        alarm.challenges.remove(at: index)
                                    }
                                )
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 14)
                    
                    // 5. Anti-Sleep & Wake-Up Verification
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Enable Anti-Sleep Verification", isOn: $alarm.wakeUpVerification.isEnabled)
                            .toggleStyle(.switch)
                        
                        if alarm.wakeUpVerification.isEnabled {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Requires you to confirm you are awake after dismissal. If you miss verification, alarm re-engages at maximum volume!")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textMuted)
                                
                                HStack(spacing: 16) {
                                    Picker("Delay", selection: $alarm.wakeUpVerification.delayMinutes) {
                                        Text("3 Minutes").tag(3)
                                        Text("5 Minutes").tag(5)
                                        Text("10 Minutes").tag(10)
                                        Text("15 Minutes").tag(15)
                                    }
                                    .frame(width: 140)
                                    
                                    Picker("Stages", selection: $alarm.wakeUpVerification.stagesCount) {
                                        Text("1 Stage").tag(1)
                                        Text("2 Stages").tag(2)
                                        Text("3 Stages").tag(3)
                                    }
                                    .frame(width: 130)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 14)
                    
                    // 6. Snooze & Backup Alarm
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Allow Snooze", isOn: $alarm.snooze.isEnabled)
                            .toggleStyle(.switch)
                        
                        if alarm.snooze.isEnabled {
                            HStack(spacing: 16) {
                                Picker("Duration", selection: $alarm.snooze.durationMinutes) {
                                    Text("3 Min").tag(3)
                                    Text("5 Min").tag(5)
                                    Text("9 Min").tag(9)
                                }
                                .frame(width: 110)
                                
                                Picker("Max Snoozes", selection: $alarm.snooze.maxCount) {
                                    Text("1 time").tag(1)
                                    Text("2 times").tag(2)
                                    Text("3 times").tag(3)
                                }
                                .frame(width: 130)
                            }
                        }
                        
                        Divider().background(Theme.borderSubtle)
                        
                        Toggle("Emergency Backup Alarm", isOn: $alarm.backupAlarmEnabled)
                            .toggleStyle(.switch)
                        
                        if alarm.backupAlarmEnabled {
                            Text("If challenges are not completed within 60s, a secondary piercing sound triggers simultaneously.")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 14)
                }
                .padding(24)
            }
        }
        .frame(minWidth: 640, minHeight: 700)
        .background(Theme.bgDeep.ignoresSafeArea())
    }
    
    private func applyPreset(_ preset: AlarmPreset) {
        selectedPreset = preset
        alarm.preset = preset
        alarm.soundId = preset.defaultSoundId
        alarm.volume = preset.defaultVolume
        alarm.gradualVolume = preset.defaultRampDuration > 0
        alarm.volumeRampDuration = preset.defaultRampDuration
        alarm.snooze.isEnabled = preset.defaultSnoozeAllowed
        alarm.snooze.maxCount = preset.defaultMaxSnoozes
        alarm.snooze.remainingCount = preset.defaultMaxSnoozes
        alarm.challenges = preset.defaultChallenges
        alarm.wakeUpVerification.isEnabled = preset.defaultVerificationEnabled
        alarm.wakeUpVerification.delayMinutes = preset.defaultVerificationDelayMinutes
        alarm.wakeUpVerification.stagesCount = preset.defaultVerificationStages
    }
    
    private func toggleSoundPreview() {
        if isPreviewingSound {
            AudioEngine.shared.stopPreview()
            isPreviewingSound = false
        } else {
            AudioEngine.shared.previewSound(soundId: alarm.soundId, volume: alarm.volume)
            isPreviewingSound = true
        }
    }
}

// MARK: - Challenge Row Config View
private struct ChallengeRowConfigView: View {
    let index: Int
    @Binding var challenge: ChallengeConfig
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index).")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textDim)
            
            Image(systemName: challenge.type.iconName)
                .font(.system(size: 14))
                .foregroundColor(Theme.accentAmber)
            
            Text(challenge.type.rawValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Picker("Difficulty", selection: $challenge.difficulty) {
                ForEach(ChallengeDifficulty.allCases) { diff in
                    Text(diff.rawValue).tag(diff)
                }
            }
            .frame(width: 100)
            
            if challenge.type == .math || challenge.type == .memory || challenge.type == .pattern {
                Picker("Questions", selection: $challenge.questionCount) {
                    ForEach([1, 2, 3, 5, 8, 10, 15], id: \.self) { count in
                        Text("\(count) Qs").tag(count)
                    }
                }
                .frame(width: 85)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accentRed.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Theme.bgDeep)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderSubtle, lineWidth: 1))
    }
}

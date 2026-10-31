import SwiftUI
import HardcoreAlarmCore

public struct AlarmListView: View {
    @ObservedObject var scheduler = AlarmScheduler.shared
    @UIState private var filterTab: FilterTab = .all
    @UIState private var previewingSoundId: String? = nil
    
    public let onAddAlarm: () -> Void
    public let onEditAlarm: (Alarm) -> Void
    
    public enum FilterTab: String, CaseIterable, Identifiable {
        case all = "All Alarms"
        case active = "Active"
        case weekdays = "Weekdays"
        case weekends = "Weekends"
        
        public var id: String { rawValue }
    }
    
    public init(onAddAlarm: @escaping () -> Void, onEditAlarm: @escaping () -> Void) {
        self.onAddAlarm = onAddAlarm
        self.onEditAlarm = { _ in onEditAlarm() }
    }
    
    public init(onAddAlarm: @escaping () -> Void, onEditAlarmWithModel: @escaping (Alarm) -> Void) {
        self.onAddAlarm = onAddAlarm
        self.onEditAlarm = onEditAlarmWithModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ALARMS MANAGEMENT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentAmber)
                    Text("Configured Hardcore Alarms")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                // Add Alarm Button
                GlowingButton(title: "New Alarm", icon: "plus", style: .primary) {
                    onAddAlarm()
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            
            // Filter Tabs Bar
            HStack(spacing: 8) {
                ForEach(FilterTab.allCases) { tab in
                    Button(action: { filterTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(filterTab == tab ? Theme.textPrimary : Theme.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(filterTab == tab ? Theme.bgCardHover : Color.clear)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(filterTab == tab ? Theme.borderMedium : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
            
            Divider()
                .background(Theme.borderSubtle)
            
            // Alarms List
            let filtered = filteredAlarms
            if filtered.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "bell.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textDim)
                    Text("No alarms match '\(filterTab.rawValue)'")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                    Text("Create a new alarm or change your filter tab.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textMuted)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 14) {
                        ForEach(filtered) { alarm in
                            AlarmCardView(
                                alarm: alarm,
                                isPreviewingSound: previewingSoundId == alarm.soundId,
                                onToggle: {
                                    scheduler.toggleAlarm(id: alarm.id)
                                },
                                onEdit: {
                                    onEditAlarm(alarm)
                                },
                                onDuplicate: {
                                    scheduler.duplicateAlarm(id: alarm.id)
                                },
                                onSkipNext: {
                                    scheduler.skipNextOccurrence(id: alarm.id)
                                },
                                onDelete: {
                                    scheduler.removeAlarm(id: alarm.id)
                                },
                                onPreviewSound: {
                                    toggleSoundPreview(soundId: alarm.soundId)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
    }
    
    private var filteredAlarms: [Alarm] {
        switch filterTab {
        case .all:
            return scheduler.alarms
        case .active:
            return scheduler.alarms.filter(\.isEnabled)
        case .weekdays:
            return scheduler.alarms.filter { !$0.repeatDays.intersection(Weekday.weekdaysOnly).isEmpty }
        case .weekends:
            return scheduler.alarms.filter { !$0.repeatDays.intersection(Weekday.weekendsOnly).isEmpty }
        }
    }
    
    private func toggleSoundPreview(soundId: String) {
        if previewingSoundId == soundId {
            AudioEngine.shared.stopPreview()
            previewingSoundId = nil
        } else {
            AudioEngine.shared.previewSound(soundId: soundId)
            previewingSoundId = soundId
        }
    }
}

// MARK: - Alarm Card View
private struct AlarmCardView: View {
    let alarm: Alarm
    let isPreviewingSound: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onSkipNext: () -> Void
    let onDelete: () -> Void
    let onPreviewSound: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            // Top Row: Time, Toggle, Badges
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        Text(alarm.formattedTime)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(alarm.isEnabled ? Theme.textPrimary : Theme.textDim)
                        
                        Toggle("", isOn: Binding(
                            get: { alarm.isEnabled },
                            set: { _ in onToggle() }
                        ))
                        .toggleStyle(.switch)
                    }
                    
                    Text(alarm.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(alarm.isEnabled ? Theme.textSecondary : Theme.textDim)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    PresetBadge(preset: alarm.preset)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.system(size: 10))
                        Text(alarm.repeatSummary)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Theme.textMuted)
                }
            }
            
            if !alarm.details.isEmpty {
                Text(alarm.details)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Middle specs line
            HStack(spacing: 12) {
                // Sound info & preview button
                Button(action: onPreviewSound) {
                    HStack(spacing: 5) {
                        Image(systemName: isPreviewingSound ? "stop.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isPreviewingSound ? Theme.accentRed : Theme.accentAmber)
                        Text(alarm.soundId.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.bgDeep)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                // Challenges count tag
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.accentAmber)
                    Text("\(alarm.challenges.count) Challenge\(alarm.challenges.count == 1 ? "" : "s")")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.bgDeep)
                .cornerRadius(6)
                
                // Snooze policy
                HStack(spacing: 4) {
                    Image(systemName: alarm.snooze.isEnabled ? "moon.zzz.fill" : "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(alarm.snooze.isEnabled ? Theme.accentBlue : Theme.accentRed)
                    Text(alarm.snooze.isEnabled ? "Snooze (\(alarm.snooze.maxCount)x)" : "No Snooze")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.bgDeep)
                .cornerRadius(6)
                
                if alarm.wakeUpVerification.isEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.accentGreen)
                        Text("Anti-Sleep (\(alarm.wakeUpVerification.delayMinutes)m)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.bgDeep)
                    .cornerRadius(6)
                }
                
                Spacer()
            }
            
            Divider()
                .background(Theme.borderSubtle)
            
            // Actions Row
            HStack {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button(action: onDuplicate) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Duplicate")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
                
                Button(action: onSkipNext) {
                    HStack(spacing: 4) {
                        Image(systemName: "forward.fill")
                        Text(alarm.skipNextOccurrence ? "Resume" : "Skip Next")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(alarm.skipNextOccurrence ? Theme.accentAmber : Theme.textMuted)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.accentRed.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 16, strokeColor: alarm.isEnabled ? Theme.borderMedium : Theme.borderSubtle)
    }
}

import SwiftUI
import HardcoreAlarmCore

public struct DashboardView: View {
    @ObservedObject var scheduler = AlarmScheduler.shared
    @ObservedObject var verificationManager = WakeUpVerificationManager.shared
    
    @UIState private var currentTime = Date()
    @UIState private var timeTimer: Timer?
    @UIState private var quickHour: Int = 7
    @UIState private var quickMinute: Int = 0
    @UIState private var quickPreset: AlarmPreset = .hardcore
    @UIState private var showAlarmCreatedNotice: Bool = false
    
    public let onNavigateToAlarms: () -> Void
    public let onNavigateToStats: () -> Void
    public let onNavigateToSettings: () -> Void
    public let onEditAlarm: (Alarm) -> Void
    
    public init(
        onNavigateToAlarms: @escaping () -> Void,
        onNavigateToStats: @escaping () -> Void,
        onNavigateToSettings: @escaping () -> Void,
        onEditAlarm: @escaping (Alarm) -> Void
    ) {
        self.onNavigateToAlarms = onNavigateToAlarms
        self.onNavigateToStats = onNavigateToStats
        self.onNavigateToSettings = onNavigateToSettings
        self.onEditAlarm = onEditAlarm
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                // Top Bar: Clock & Status
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentDayString.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentAmber)
                        
                        Text(currentDateString)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Main Digital Clock
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(mainTimeString)
                            .font(Theme.clockFont(size: 38))
                            .foregroundColor(Theme.textPrimary)
                        Text(secondsString)
                            .font(Theme.clockFont(size: 20))
                            .foregroundColor(Theme.accentAmber)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.bgDeep)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderSubtle, lineWidth: 1))
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                
                // Anti-Sleep Verification Pending Banner (if active)
                if case .pending(let title, let secondsRemaining, let stage, let total) = verificationManager.status {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.accentAmber)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ANTI-SLEEP VERIFICATION PENDING")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.accentAmber)
                            Text("\(title) • Stage \(stage) of \(total) due in \(secondsRemaining / 60)m \(secondsRemaining % 60)s")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text("\(secondsRemaining)s")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentAmber)
                    }
                    .padding(16)
                    .background(Theme.accentAmber.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accentAmber.opacity(0.35), lineWidth: 1))
                    .padding(.horizontal, 28)
                }
                
                // HERO: Next Upcoming Alarm Card
                VStack(spacing: 18) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(scheduler.nextUpcomingAlarm != nil ? Theme.accentGreen : Theme.textDim)
                                .frame(width: 8, height: 8)
                            Text("NEXT SCHEDULED ALARM")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if let next = scheduler.nextUpcomingAlarm {
                            PresetBadge(preset: next.preset)
                        }
                    }
                    
                    if let next = scheduler.nextUpcomingAlarm {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(next.formattedTime)
                                    .font(.system(size: 46, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                
                                Text(next.title)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Theme.textSecondary)
                                
                                HStack(spacing: 8) {
                                    Text(next.repeatSummary)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.textMuted)
                                    
                                    if next.skipNextOccurrence {
                                        Text("SKIPPING NEXT OCCURRENCE")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.accentAmber)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Animated Live Countdown
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("TIME REMAINING")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                
                                DigitalCountdownView(remainingSeconds: scheduler.timeUntilNextAlarm)
                            }
                        }
                        
                        Divider()
                            .background(Theme.borderSubtle)
                        
                        // Action buttons on next alarm
                        HStack {
                            Button(action: {
                                onEditAlarm(next)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "slider.horizontal.3")
                                    Text("Configure Alarm")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Button(action: {
                                scheduler.skipNextOccurrence(id: next.id)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "forward.fill")
                                    Text(next.skipNextOccurrence ? "Resume Schedule" : "Skip Next Once")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(next.skipNextOccurrence ? Theme.accentAmber : Theme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "alarm")
                                .font(.system(size: 38))
                                .foregroundColor(Theme.textDim)
                            Text("No Alarms Enabled")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                            Text("Create a new alarm below or enable an existing one from the alarms list.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.vertical, 24)
                    }
                }
                .padding(24)
                .glassCard(cornerRadius: 20, strokeColor: scheduler.nextUpcomingAlarm != nil ? Theme.borderActive : Theme.borderSubtle, isHighlighted: scheduler.nextUpcomingAlarm != nil)
                .padding(.horizontal, 28)
                
                // Weekly Schedule Overview Bar
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("WEEKLY SCHEDULE OVERVIEW")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Button("View All Alarms →") {
                            onNavigateToAlarms()
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.accentAmber)
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(Weekday.allCases.sorted(), id: \.self) { day in
                            let activeAlarms = scheduler.alarms.filter { $0.isEnabled && $0.repeatDays.contains(day) }
                            let isToday = Calendar.current.component(.weekday, from: currentTime) == day.rawValue
                            
                            VStack(spacing: 6) {
                                Text(day.shortName.uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(isToday ? Theme.accentAmber : Theme.textMuted)
                                
                                if let firstAlarm = activeAlarms.first {
                                    VStack(spacing: 2) {
                                        Text(firstAlarm.formattedTime24Hour)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.textPrimary)
                                        
                                        Circle()
                                            .fill(firstAlarm.preset == .impossible || firstAlarm.preset == .extreme ? Theme.accentRed : Theme.accentAmber)
                                            .frame(width: 5, height: 5)
                                    }
                                } else {
                                    Text("—")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textDim)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isToday ? Theme.accentAmber.opacity(0.1) : Theme.bgDeep)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isToday ? Theme.accentAmber.opacity(0.4) : Theme.borderSubtle, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 28)
                
                // Quick Alarm Creation Bar
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("QUICK ALARM CREATION")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        if showAlarmCreatedNotice {
                            Text("✓ Alarm Created!")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.accentGreen)
                                .transition(.opacity)
                        }
                    }
                    
                    HStack(spacing: 14) {
                        // Time Pickers
                        HStack(spacing: 6) {
                            Picker("Hour", selection: $quickHour) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text(String(format: "%02d", h)).tag(h)
                                }
                            }
                            .frame(width: 70)
                            
                            Text(":")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textDim)
                            
                            Picker("Minute", selection: $quickMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                                    Text(String(format: "%02d", m)).tag(m)
                                }
                            }
                            .frame(width: 70)
                        }
                        
                        // Preset Picker
                        Picker("Preset", selection: $quickPreset) {
                            ForEach(AlarmPreset.allCases.filter { $0 != .custom }, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .frame(width: 140)
                        
                        GlowingButton(title: "Add Quick Alarm", icon: "plus.circle.fill", style: .primary) {
                            createQuickAlarm()
                        }
                        
                        Spacer()
                        
                        // Fast 5-Second Test Button
                        Button(action: triggerImmediateTestAlarm) {
                            HStack(spacing: 5) {
                                Image(systemName: "bolt.fill")
                                Text("Test in 5s")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.accentRed.opacity(0.12))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accentRed.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 28)
                
                // Wake-Up Statistics Quick Summary
                WakeUpStatsSnippetView(onTapStats: onNavigateToStats)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
        .onAppear {
            timeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.currentTime = Date()
                }
            }
        }
        .onDisappear {
            timeTimer?.invalidate()
            timeTimer = nil
        }
    }
    
    // MARK: - Helpers
    private var currentDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: currentTime)
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }
    
    private var mainTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }
    
    private var secondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = ":ss"
        return formatter.string(from: currentTime)
    }
    
    private func createQuickAlarm() {
        let newAlarm = Alarm.makePresetAlarm(preset: quickPreset, hour: quickHour, minute: quickMinute)
        scheduler.addAlarm(newAlarm)
        
        withAnimation {
            showAlarmCreatedNotice = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { self.showAlarmCreatedNotice = false }
        }
    }
    
    private func triggerImmediateTestAlarm() {
        let cal = Calendar.current
        let testDate = Date().addingTimeInterval(5)
        let h = cal.component(.hour, from: testDate)
        let m = cal.component(.minute, from: testDate)
        
        var testAlarm = Alarm.makePresetAlarm(preset: .hardcore, hour: h, minute: m)
        testAlarm.title = "⚡️ Immediate Test Alarm (5s)"
        testAlarm.repeatDays = [] // one-time
        testAlarm.volumeRampDuration = 5.0
        
        scheduler.addAlarm(testAlarm)
    }
}

// MARK: - WakeUp Stats Snippet
private struct WakeUpStatsSnippetView: View {
    let onTapStats: () -> Void
    
    var body: some View {
        let history = PersistenceService.shared.loadHistory()
        let totalCount = history.count
        let successCount = history.filter(\.wasSuccessful).count
        let successRate = totalCount > 0 ? Int((Double(successCount) / Double(totalCount)) * 100) : 100
        let avgSolveTime = totalCount > 0 ? Int(history.map(\.solveDurationSeconds).reduce(0, +) / Double(totalCount)) : 42
        
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("WAKE-UP PERFORMANCE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button("Detailed Analytics →", action: onTapStats)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.accentAmber)
                    .buttonStyle(.plain)
            }
            
            HStack(spacing: 16) {
                MetricSnippetBox(title: "SUCCESS RATE", value: "\(successRate)%", icon: "checkmark.seal.fill", color: Theme.accentGreen)
                MetricSnippetBox(title: "AVG SOLVE TIME", value: "\(avgSolveTime)s", icon: "stopwatch.fill", color: Theme.accentBlue)
                MetricSnippetBox(title: "STREAK", value: "7 DAYS", icon: "flame.fill", color: Theme.accentAmber)
                MetricSnippetBox(title: "VERIFICATIONS", value: "100%", icon: "shield.fill", color: Theme.accentViolet)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 16)
    }
}

private struct MetricSnippetBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.bgDeep)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.borderSubtle, lineWidth: 1))
    }
}

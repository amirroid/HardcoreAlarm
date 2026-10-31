import SwiftUI
import HardcoreAlarmCore

public struct AlarmOverlayView: View {
    public let alarm: Alarm
    @UIState private var currentTime = Date()
    @UIState private var timeTimer: Timer?
    @UIState private var solveMistakes: Int = 0
    @UIState private var solveDuration: TimeInterval = 0
    @UIState private var pulseState: Bool = false
    
    public var onDismissCompleted: () -> Void
    public var onSnooze: () -> Void
    
    public init(alarm: Alarm, onDismissCompleted: @escaping () -> Void, onSnooze: @escaping () -> Void) {
        self.alarm = alarm
        self.onDismissCompleted = onDismissCompleted
        self.onSnooze = onSnooze
    }
    
    public var body: some View {
        ZStack {
            // High-tech emergency background
            Theme.bgDeep
                .ignoresSafeArea()
            
            // Subtle ambient pulsing emergency glow
            RadialGradient(
                colors: [
                    (alarm.preset == .impossible || alarm.preset == .extreme ? Theme.accentRed : Theme.accentAmber).opacity(pulseState ? 0.22 : 0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 700
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseState)
            
            VStack(spacing: 24) {
                // Urgent Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.accentRed)
                        Text("🚨 HARDCORE ALARM ACTIVATED")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(Theme.accentRed)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Theme.accentRed.opacity(0.15))
                            .overlay(Capsule().stroke(Theme.accentRed.opacity(0.4), lineWidth: 1))
                    )
                    
                    Spacer()
                    
                    PresetBadge(preset: alarm.preset)
                }
                .padding(.horizontal, 36)
                .padding(.top, 32)
                
                // Clock & Alarm Title
                VStack(spacing: 6) {
                    Text(timeString)
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(alarm.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                    
                    if !alarm.details.isEmpty {
                        Text(alarm.details)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                
                // Active Challenges Container
                ScrollView(.vertical, showsIndicators: false) {
                    MultiStepContainerView(
                        challenges: alarm.challenges,
                        onAllCompleted: { duration, mistakes, types in
                            handleChallengeSolved(duration: duration, mistakes: mistakes, types: types)
                        },
                        onMistake: {
                            solveMistakes += 1
                        }
                    )
                    .padding(.vertical, 10)
                }
                .frame(maxHeight: 520)
                
                Spacer()
                
                // Bottom Snooze / Dismiss Restrictions Bar
                HStack(spacing: 16) {
                    if alarm.snooze.isEnabled && alarm.snooze.remainingCount > 0 {
                        Button(action: onSnooze) {
                            HStack(spacing: 6) {
                                Image(systemName: "moon.zzz.fill")
                                Text("Snooze \(alarm.snooze.durationMinutes)m (\(alarm.snooze.remainingCount) left)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.bgCard)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.borderMedium, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Theme.accentRed)
                            Text("SNOOZE DISABLED • MUST COMPLETE CHALLENGES TO SILENCE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.bgDeep.opacity(0.8))
                        .cornerRadius(8)
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            pulseState = true
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
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
    
    private func handleChallengeSolved(duration: TimeInterval, mistakes: Int, types: [ChallengeType]) {
        print("[AlarmOverlayView] Challenge solved! Duration: \(duration)s, Mistakes: \(mistakes)")
        
        let record = AlarmHistoryRecord(
            alarmId: alarm.id,
            alarmTitle: alarm.title,
            scheduledTime: Date(),
            firedTime: Date().addingTimeInterval(-duration),
            dismissedTime: Date(),
            wasSuccessful: true,
            wasDismissedViaChallenge: true,
            solveDurationSeconds: duration,
            snoozesUsed: 0,
            mistakeCount: mistakes,
            challengesCompleted: types,
            verificationStatus: alarm.wakeUpVerification.isEnabled ? .pending : .notApplicable,
            difficulty: alarm.challenges.first?.difficulty ?? .medium
        )
        
        PersistenceService.shared.appendHistoryRecord(record)
        onDismissCompleted()
    }
}

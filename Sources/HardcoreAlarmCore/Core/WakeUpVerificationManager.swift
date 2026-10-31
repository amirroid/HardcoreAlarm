import Foundation
import Combine

public final class WakeUpVerificationManager: ObservableObject, @unchecked Sendable {
    public static let shared = WakeUpVerificationManager()
    
    public enum Status: Equatable, Sendable {
        case idle
        case pending(alarmTitle: String, secondsRemaining: Int, stage: Int, totalStages: Int)
        case promptActive(alarmTitle: String, secondsRemaining: Int, stage: Int)
        case failedReAlarm(alarmTitle: String)
        case verifiedComplete
    }
    
    @Published public private(set) var status: Status = .idle
    
    private var verificationTimer: Timer?
    private var promptTimer: Timer?
    private var currentAlarm: Alarm?
    private var currentStage: Int = 1
    private var totalStages: Int = 1
    private var pendingSeconds: Int = 0
    private var promptSecondsRemaining: Int = 60
    
    // Callback when re-alarm needs to be triggered
    public var onReAlarmTriggered: ((Alarm) -> Void)?
    public var onVerificationPromptPresented: (() -> Void)?
    public var onVerificationCompleted: (() -> Void)?
    
    public init() {}
    
    public func startVerification(for alarm: Alarm) {
        guard alarm.wakeUpVerification.isEnabled else { return }
        
        currentAlarm = alarm
        currentStage = 1
        totalStages = max(1, alarm.wakeUpVerification.stagesCount)
        startStageCountdown()
    }
    
    private func startStageCountdown() {
        guard let alarm = currentAlarm else { return }
        
        verificationTimer?.invalidate()
        promptTimer?.invalidate()
        
        pendingSeconds = alarm.wakeUpVerification.delayMinutes * 60
        status = .pending(
            alarmTitle: alarm.title,
            secondsRemaining: pendingSeconds,
            stage: currentStage,
            totalStages: totalStages
        )
        
        NotificationManager.shared.scheduleVerificationNotification(delaySeconds: TimeInterval(pendingSeconds))
        
        verificationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.pendingSeconds -= 1
            if self.pendingSeconds <= 0 {
                timer.invalidate()
                self.verificationTimer = nil
                self.presentVerificationPrompt()
            } else {
                self.status = .pending(
                    alarmTitle: alarm.title,
                    secondsRemaining: self.pendingSeconds,
                    stage: self.currentStage,
                    totalStages: self.totalStages
                )
            }
        }
    }
    
    private func presentVerificationPrompt() {
        guard let alarm = currentAlarm else { return }
        
        promptSecondsRemaining = 60 // 60 seconds to respond
        status = .promptActive(
            alarmTitle: alarm.title,
            secondsRemaining: promptSecondsRemaining,
            stage: currentStage
        )
        
        onVerificationPromptPresented?()
        
        promptTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.promptSecondsRemaining -= 1
            if self.promptSecondsRemaining <= 0 {
                timer.invalidate()
                self.promptTimer = nil
                self.triggerReAlarm()
            } else {
                self.status = .promptActive(
                    alarmTitle: alarm.title,
                    secondsRemaining: self.promptSecondsRemaining,
                    stage: self.currentStage
                )
            }
        }
    }
    
    public func confirmAwake() {
        promptTimer?.invalidate()
        promptTimer = nil
        
        if currentStage < totalStages {
            currentStage += 1
            startStageCountdown()
        } else {
            status = .verifiedComplete
            NotificationManager.shared.cancelVerificationNotification()
            onVerificationCompleted?()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.reset()
            }
        }
    }
    
    private func triggerReAlarm() {
        guard let alarm = currentAlarm else { return }
        status = .failedReAlarm(alarmTitle: alarm.title)
        print("[WakeUpVerificationManager] User missed verification window! Triggering hardcore re-alarm!")
        onReAlarmTriggered?(alarm)
    }
    
    public func reset() {
        verificationTimer?.invalidate()
        verificationTimer = nil
        promptTimer?.invalidate()
        promptTimer = nil
        currentAlarm = nil
        status = .idle
        NotificationManager.shared.cancelVerificationNotification()
    }
}

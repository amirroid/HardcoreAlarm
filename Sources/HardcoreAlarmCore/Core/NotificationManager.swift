import Foundation
import UserNotifications

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationManager()
    
    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }
    
    public override init() {
        super.init()
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = self
        }
    }
    
    public func requestAuthorization(completion: @Sendable @escaping (Bool) -> Void = { _ in }) {
        center?.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[NotificationManager] Auth error: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    public func checkAuthorizationStatus(completion: @Sendable @escaping (UNAuthorizationStatus) -> Void) {
        center?.getNotificationSettings { settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    public func scheduleAlarmNotification(alarm: Alarm, fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 HARDCORE ALARM: \(alarm.title)"
        content.body = "Wake up immediately! Hardcore challenges are required to dismiss this alarm."
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .timeSensitive
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "alarm_\(alarm.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        center?.add(request) { error in
            if let error = error {
                print("[NotificationManager] Failed to schedule notification: \(error)")
            }
        }
    }
    
    public func cancelAlarmNotification(alarmId: UUID) {
        center?.removePendingNotificationRequests(withIdentifiers: ["alarm_\(alarmId.uuidString)"])
    }
    
    public func scheduleVerificationNotification(delaySeconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ WAKE-UP VERIFICATION DUE"
        content.body = "Confirm you are still awake! Tap now to complete your secondary challenge before re-alarm triggers."
        content.sound = UNNotificationSound.defaultCritical
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "wakeup_verification",
            content: content,
            trigger: trigger
        )
        
        center?.add(request)
    }
    
    public func cancelVerificationNotification() {
        center?.removePendingNotificationRequests(withIdentifiers: ["wakeup_verification"])
    }
    
    // Foreground notification handling
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

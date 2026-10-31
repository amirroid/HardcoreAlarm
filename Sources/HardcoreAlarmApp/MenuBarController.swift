import AppKit
import SwiftUI
import HardcoreAlarmCore

@MainActor
public final class MenuBarController: NSObject {
    public static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    
    public override init() {
        super.init()
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "alarm.fill", accessibilityDescription: "Hardcore Alarm")
            button.imagePosition = .imageLeading
        }
        
        updateMenu()
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMenu()
            }
        }
    }
    
    public func updateMenu() {
        guard let statusItem = statusItem else { return }
        
        let menu = NSMenu()
        
        // Header Item: Next Alarm
        if let next = AlarmScheduler.shared.nextUpcomingAlarm, let remaining = AlarmScheduler.shared.timeUntilNextAlarm {
            let mins = Int(remaining) / 60
            let hours = mins / 60
            let remMins = mins % 60
            
            let timeStr = hours > 0 ? "\(hours)h \(remMins)m" : "\(remMins)m"
            let titleItem = NSMenuItem(title: "🚨 Next: \(next.title) (\(next.formattedTime))", action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)
            
            let countItem = NSMenuItem(title: "⏱️ Firing in \(timeStr)", action: nil, keyEquivalent: "")
            countItem.isEnabled = false
            menu.addItem(countItem)
            
            statusItem.button?.title = " \(next.formattedTime24Hour)"
        } else {
            let noAlarmItem = NSMenuItem(title: "No Alarms Scheduled", action: nil, keyEquivalent: "")
            noAlarmItem.isEnabled = false
            menu.addItem(noAlarmItem)
            statusItem.button?.title = ""
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Dashboard
        let openItem = NSMenuItem(title: "Open Dashboard", action: #selector(openApp), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        // Quick Test Alarm (5s)
        let testItem = NSMenuItem(title: "Trigger 5-Second Test Alarm", action: #selector(triggerTestAlarm), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let isLocked = AlarmScheduler.shared.isAlarmActive || WakeUpVerificationManager.shared.isVerificationActive
        let quitItem: NSMenuItem
        if isLocked {
            quitItem = NSMenuItem(title: "🔒 Quit Blocked (Alarm Ringing)", action: #selector(quitApp), keyEquivalent: "")
        } else {
            quitItem = NSMenuItem(title: "Quit Hardcore Alarm", action: #selector(quitApp), keyEquivalent: "q")
        }
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc public func openApp() {
        WindowManager.shared.showDashboardWindow()
    }
    
    @objc private func triggerTestAlarm() {
        let cal = Calendar.current
        let testDate = Date().addingTimeInterval(5)
        let h = cal.component(.hour, from: testDate)
        let m = cal.component(.minute, from: testDate)
        
        var testAlarm = Alarm.makePresetAlarm(preset: .hardcore, hour: h, minute: m)
        testAlarm.title = "⚡️ Immediate Test Alarm (5s)"
        testAlarm.repeatDays = []
        testAlarm.volumeRampDuration = 5.0
        
        AlarmScheduler.shared.addAlarm(testAlarm)
    }
    
    @objc private func quitApp() {
        if AlarmScheduler.shared.isAlarmActive || WakeUpVerificationManager.shared.isVerificationActive {
            NSSound.beep()
            NotificationCenter.default.post(name: NSNotification.Name("HardcoreAlarmQuitAttempted"), object: nil)
            return
        }
        NSApp.terminate(nil)
    }
}

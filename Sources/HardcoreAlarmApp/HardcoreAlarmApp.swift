import SwiftUI
import AppKit
import HardcoreAlarmCore

@main
struct HardcoreAlarmApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @UIState private var currentTab: NavigationTab = .dashboard
    @UIState private var editingAlarm: Alarm? = nil
    @UIState private var isEditorPresented: Bool = false
    
    init() {}
    
    enum NavigationTab: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case alarms = "Alarms"
        case statistics = "Statistics"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .dashboard: return "clock.fill"
            case .alarms: return "bell.badge.fill"
            case .statistics: return "chart.bar.xaxis"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    public var body: some Scene {
        WindowGroup {
            ZStack {
                Theme.bgDeep.ignoresSafeArea()
                
                HStack(spacing: 0) {
                    // Navigation Sidebar
                    VStack(alignment: .leading, spacing: 12) {
                        // App Brand
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.accentAmber)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("HARDCORE")
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)
                                Text("ALARM SYSTEM")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.accentAmber)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                        
                        Divider().background(Theme.borderSubtle).padding(.horizontal, 12)
                        
                        // Nav Items
                        VStack(spacing: 4) {
                            ForEach(NavigationTab.allCases) { tab in
                                Button(action: { currentTab = tab }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: tab.iconName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(currentTab == tab ? Theme.accentAmber : Theme.textMuted)
                                            .frame(width: 20)
                                        
                                        Text(tab.rawValue)
                                            .font(.system(size: 13, weight: currentTab == tab ? .bold : .medium))
                                            .foregroundColor(currentTab == tab ? Theme.textPrimary : Theme.textSecondary)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(currentTab == tab ? Theme.bgCardHover : Color.clear)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(currentTab == tab ? Theme.borderMedium : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        Spacer()
                        
                        // Status Footer
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Theme.accentGreen)
                                    .frame(width: 7, height: 7)
                                Text("System Guard Active")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Text("Apple Silicon Native • v1.0")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.textDim)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .frame(width: 210)
                    .background(Theme.bgSecondary)
                    
                    Divider().background(Theme.borderSubtle)
                    
                    // Main Content Canvas
                    Group {
                        switch currentTab {
                        case .dashboard:
                            DashboardView(
                                onNavigateToAlarms: { currentTab = .alarms },
                                onNavigateToStats: { currentTab = .statistics },
                                onNavigateToSettings: { currentTab = .settings },
                                onEditAlarm: { alarm in
                                    editingAlarm = alarm
                                    isEditorPresented = true
                                }
                            )
                        case .alarms:
                            AlarmListView(
                                onAddAlarm: {
                                    editingAlarm = nil
                                    isEditorPresented = true
                                },
                                onEditAlarmWithModel: { alarm in
                                    editingAlarm = alarm
                                    isEditorPresented = true
                                }
                            )
                        case .statistics:
                            StatisticsView()
                        case .settings:
                            SettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 980, minHeight: 680)
            .background(WindowAccessor { window in
                WindowManager.shared.setMainWindow(window)
            })
            .onOpenURL { _ in
                MenuBarController.shared.openApp()
            }
            .sheet(isPresented: $isEditorPresented) {
                AlarmEditorView(alarm: editingAlarm) { savedAlarm in
                    if let index = AlarmScheduler.shared.alarms.firstIndex(where: { $0.id == savedAlarm.id }) {
                        var list = AlarmScheduler.shared.alarms
                        list[index] = savedAlarm
                        AlarmScheduler.shared.updateAlarms(list)
                    } else {
                        AlarmScheduler.shared.addAlarm(savedAlarm)
                    }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit Hardcore Alarm") {
                    if AlarmScheduler.shared.isAlarmActive || WakeUpVerificationManager.shared.isVerificationActive {
                        NSSound.beep()
                        NotificationCenter.default.post(name: NSNotification.Name("HardcoreAlarmQuitAttempted"), object: nil)
                        return
                    }
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}

// MARK: - App Delegate
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventMonitor: Any?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup Hardcore Lockout key interceptor (swallows Cmd+Q, Cmd+W, Cmd+M, Cmd+H, Esc during active alarm/verification)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let isAlarmActive = AlarmScheduler.shared.isAlarmActive
            let isVerificationActive = WakeUpVerificationManager.shared.isVerificationActive
            
            if isAlarmActive || isVerificationActive {
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                
                if flags.contains(.command) {
                    if let chars = event.charactersIgnoringModifiers?.lowercased() {
                        if chars == "q" || chars == "w" || chars == "m" || chars == "h" {
                            NSSound.beep()
                            NotificationCenter.default.post(name: NSNotification.Name("HardcoreAlarmQuitAttempted"), object: nil)
                            return nil // Completely block and drop key event!
                        }
                    }
                }
                
                if event.keyCode == 53 { // Escape
                    NSSound.beep()
                    NotificationCenter.default.post(name: NSNotification.Name("HardcoreAlarmQuitAttempted"), object: nil)
                    return nil
                }
            }
            return event
        }
        
        // Setup menu bar extra
        MenuBarController.shared.setup()
        
        // Setup Alarm Trigger Handlers
        AlarmScheduler.shared.onAlarmTriggered = { alarm in
            // 1. Activate macOS Power Wake Lock
            PowerManager.shared.activateWakeLock(reason: "Hardcore Alarm: \(alarm.title)")
            
            // 2. Start Audio Engine with volume ramp & voice announcement
            AudioEngine.shared.startAlarm(
                soundId: alarm.soundId,
                volume: alarm.volume,
                gradual: alarm.gradualVolume,
                rampDuration: alarm.volumeRampDuration,
                voiceAnnouncement: alarm.voiceAnnouncementEnabled,
                alarmTitle: alarm.title
            )
            
            // 3. Present full-screen non-dismissible takeover overlay
            WindowManager.shared.presentAlarmOverlay(
                alarm: alarm,
                onDismiss: {
                    // Silenced by solving challenges!
                    AudioEngine.shared.stopAll()
                    PowerManager.shared.releaseWakeLock()
                    AlarmScheduler.shared.dismissActiveAlarm()
                    
                    // If anti-sleep verification is enabled, initiate countdown
                    if alarm.wakeUpVerification.isEnabled {
                        WakeUpVerificationManager.shared.startVerification(for: alarm)
                    }
                },
                onSnooze: {
                    AudioEngine.shared.stopAll()
                    PowerManager.shared.releaseWakeLock()
                    AlarmScheduler.shared.dismissActiveAlarm()
                    
                    // Reschedule for snooze minutes
                    let snoozeMins = alarm.snooze.durationMinutes
                    let snoozeDate = Date().addingTimeInterval(TimeInterval(snoozeMins * 60))
                    let cal = Calendar.current
                    var snoozedAlarm = alarm
                    snoozedAlarm.hour = cal.component(.hour, from: snoozeDate)
                    snoozedAlarm.minute = cal.component(.minute, from: snoozeDate)
                    snoozedAlarm.snooze.remainingCount = max(0, snoozedAlarm.snooze.remainingCount - 1)
                    snoozedAlarm.repeatDays = [] // one-time snooze
                    
                    AlarmScheduler.shared.addAlarm(snoozedAlarm)
                }
            )
        }
        
        // Setup Anti-Sleep Verification Handlers
        WakeUpVerificationManager.shared.onVerificationPromptPresented = {
            WindowManager.shared.presentVerificationPrompt {
                WakeUpVerificationManager.shared.confirmAwake()
                WindowManager.shared.closeVerification()
            }
        }
        
        WakeUpVerificationManager.shared.onReAlarmTriggered = { alarm in
            // Re-alarm triggered at maximum intensity!
            WindowManager.shared.closeVerification()
            var penaltyAlarm = alarm
            penaltyAlarm.soundId = "nuclear_klaxon"
            penaltyAlarm.volume = 1.0
            penaltyAlarm.gradualVolume = false
            penaltyAlarm.snooze.isEnabled = false
            penaltyAlarm.title = "⚠️ MISSED VERIFICATION: \(alarm.title)"
            
            AlarmScheduler.shared.triggerAlarm(penaltyAlarm)
        }
    }
    
    // Hardcore Quit Lockout: Refuse application termination while an alarm or verification is active
    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if AlarmScheduler.shared.isAlarmActive || WakeUpVerificationManager.shared.isVerificationActive {
            NSSound.beep()
            NotificationCenter.default.post(name: NSNotification.Name("HardcoreAlarmQuitAttempted"), object: nil)
            return .terminateCancel
        }
        return .terminateNow
    }
    
    // Keep app running in menu bar when main window is closed
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // Reopen main dashboard window on Dock click
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MenuBarController.shared.openApp()
        return true
    }
}

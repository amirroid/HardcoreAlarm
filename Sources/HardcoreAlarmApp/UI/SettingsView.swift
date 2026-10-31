import SwiftUI
import ServiceManagement
import UserNotifications
import HardcoreAlarmCore

public struct SettingsView: View {
    @UIState private var settings: AppSettings
    @UIState private var selectedTab: SettingsTab = .behavior
    @UIState private var notificationStatusText: String = "Checking..."
    @UIState private var showSavedNotice: Bool = false
    
    public enum SettingsTab: String, CaseIterable, Identifiable {
        case behavior = "Behavior"
        case audio = "Audio"
        case appearance = "Appearance"
        case reliability = "Reliability"
        case privacy = "Privacy"
        
        public var id: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .behavior: return "flame.fill"
            case .audio: return "speaker.wave.3.fill"
            case .appearance: return "paintbrush.fill"
            case .reliability: return "shield.lefthalf.filled"
            case .privacy: return "hand.raised.fill"
            }
        }
    }
    
    public init() {
        _settings = UIState(initialValue: PersistenceService.shared.loadSettings())
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("APPLICATION SETTINGS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentAmber)
                    Text("Preferences & System Reliability")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                if showSavedNotice {
                    Text("✓ Settings Saved")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentGreen)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Tab Buttons Bar
            HStack(spacing: 8) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 12))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? Theme.textPrimary : Theme.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Theme.bgCardHover : Color.clear)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedTab == tab ? Theme.borderMedium : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
            
            Divider()
                .background(Theme.borderSubtle)
            
            // Tab Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .behavior:
                        behaviorTab
                    case .audio:
                        audioTab
                    case .appearance:
                        appearanceTab
                    case .reliability:
                        reliabilityTab
                    case .privacy:
                        privacyTab
                    }
                }
                .padding(28)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
        .onAppear {
            checkNotifications()
        }
    }
    
    // MARK: - Behavior Tab
    private var behaviorTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("DEFAULT CHALLENGE PARAMETERS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                Picker("Default Difficulty", selection: $settings.defaultDifficulty) {
                    ForEach(ChallengeDifficulty.allCases) { diff in
                        Text(diff.rawValue).tag(diff)
                    }
                }
                .onChange(of: settings.defaultDifficulty) { _, _ in save() }
                
                Picker("Max Challenge Duration", selection: $settings.maxChallengeDurationSeconds) {
                    Text("2 Minutes").tag(120)
                    Text("3 Minutes").tag(180)
                    Text("5 Minutes").tag(300)
                    Text("10 Minutes").tag(600)
                }
                .onChange(of: settings.maxChallengeDurationSeconds) { _, _ in save() }
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
            
            VStack(alignment: .leading, spacing: 14) {
                Text("SNOOZE & PENALTY RESTRICTIONS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                Toggle("Strict Hardcore Mode: Disable All Snooze Globally", isOn: $settings.globalSnoozeRestricted)
                    .toggleStyle(.switch)
                    .onChange(of: settings.globalSnoozeRestricted) { _, _ in save() }
                
                Text("When enabled, snooze is completely forbidden across all alarms regardless of individual alarm configuration.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Audio Tab
    private var audioTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("AUDIO PLAYBACK DEFAULTS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Default Master Volume")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(settings.defaultVolume * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    Slider(value: $settings.defaultVolume, in: 0.1...1.0)
                        .tint(Theme.accentAmber)
                        .onChange(of: settings.defaultVolume) { _, _ in save() }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Volume Ramp Duration")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(settings.defaultRampDuration))s")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    Slider(value: $settings.defaultRampDuration, in: 0...60, step: 5)
                        .tint(Theme.accentAmber)
                        .onChange(of: settings.defaultRampDuration) { _, _ in save() }
                }
                
                Toggle("Voice Wake-Up Spoken Announcements", isOn: $settings.voiceAnnouncementsEnabled)
                    .toggleStyle(.switch)
                    .onChange(of: settings.voiceAnnouncementsEnabled) { _, _ in save() }
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
            
            // Built-in Sound Bank Preview
            VStack(alignment: .leading, spacing: 14) {
                Text("BUILT-IN SYNTHESIZED SOUND BANK")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                ForEach(AudioEngine.shared.builtInSounds) { sound in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sound.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text(sound.category)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
                        }
                        
                        Spacer()
                        
                        Button("Test Sound") {
                            AudioEngine.shared.previewSound(soundId: sound.id, volume: settings.defaultVolume)
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accentAmber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.bgDeep)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderSubtle, lineWidth: 1))
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Appearance Tab
    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("INTERFACE THEME & ACCENT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                Picker("Theme Mode", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { th in
                        Text(th.rawValue).tag(th)
                    }
                }
                .onChange(of: settings.theme) { _, _ in save() }
                
                Picker("Accent Color", selection: $settings.accentColor) {
                    ForEach(AccentColorTheme.allCases) { acc in
                        Text(acc.rawValue).tag(acc)
                    }
                }
                .onChange(of: settings.accentColor) { _, _ in save() }
                
                Picker("Digital Clock Style", selection: $settings.clockStyle) {
                    ForEach(ClockFontStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .onChange(of: settings.clockStyle) { _, _ in save() }
                
                Picker("Animation Intensity", selection: $settings.animationIntensity) {
                    ForEach(AnimationIntensity.allCases) { anim in
                        Text(anim.rawValue).tag(anim)
                    }
                }
                .onChange(of: settings.animationIntensity) { _, _ in save() }
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Reliability Tab
    private var reliabilityTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("MACOS SYSTEM INTEGRATION & RELIABILITY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                // Launch at login
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Launch Automatically at Login")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("Keeps background scheduler active so alarms fire reliably after logging in.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.launchAtLogin)
                        .toggleStyle(.switch)
                        .onChange(of: settings.launchAtLogin) { _, enabled in
                            updateLaunchAtLogin(enabled)
                            save()
                        }
                }
                
                Divider().background(Theme.borderSubtle)
                
                // Sleep Wake Lock
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prevent Display & System Sleep When Ringing")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("Uses native IOPMAssertion to illuminate the screen and prevent idle sleep.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.preventSleepDuringAlarm)
                        .toggleStyle(.switch)
                        .onChange(of: settings.preventSleepDuringAlarm) { _, _ in save() }
                }
                
                Divider().background(Theme.borderSubtle)
                
                // Notifications
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("macOS Notifications Permission")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("Current status: \(notificationStatusText)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentAmber)
                    }
                    Spacer()
                    Button("Request / Test") {
                        NotificationManager.shared.requestAuthorization { granted in
                            DispatchQueue.main.async {
                                self.notificationStatusText = granted ? "Authorized" : "Denied in System Settings"
                            }
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.bgDeep)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderSubtle, lineWidth: 1))
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
            
            // Transparency notice
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Theme.accentBlue)
                    Text("MACOS HARDWARE REALITY & POWER LIMITS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentBlue)
                }
                
                Text("An ordinary macOS application cannot physically turn on a completely shut-down Mac or bypass FileVault disk encryption before user login. However, while your Mac is sleeping or locked, Hardcore Alarm utilizes IOPM assertions, background timers, and sleep/wake listeners so that missed alarms trigger immediately upon display wake.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(4)
            }
            .padding(18)
            .background(Theme.accentBlue.opacity(0.1))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accentBlue.opacity(0.25), lineWidth: 1))
        }
    }
    
    // MARK: - Privacy Tab
    private var privacyTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(Theme.accentGreen)
                    Text("OFFLINE-FIRST PRIVACY MANIFESTO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentGreen)
                }
                
                Text("• 100% Local Storage: All alarms, history, and challenge records are saved exclusively to your local disk in Application Support.\n• No Analytics, No Tracking: The app performs zero telemetry, zero analytics, and zero advertising calls.\n• No Account Required: No passwords, emails, or cloud synchronization servers are ever used.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(6)
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
            
            VStack(alignment: .leading, spacing: 14) {
                Text("LOCAL DATA MANAGEMENT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                HStack(spacing: 12) {
                    Button("Clear All History Records") {
                        PersistenceService.shared.saveHistory([])
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accentRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.accentRed.opacity(0.12))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accentRed.opacity(0.3), lineWidth: 1))
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 16)
        }
    }
    
    // MARK: - Helpers
    private func save() {
        PersistenceService.shared.saveSettings(settings)
        withAnimation { showSavedNotice = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { self.showSavedNotice = false }
        }
    }
    
    private func checkNotifications() {
        NotificationManager.shared.checkAuthorizationStatus { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized: self.notificationStatusText = "Authorized"
                case .denied: self.notificationStatusText = "Denied"
                case .notDetermined: self.notificationStatusText = "Not requested yet"
                case .provisional: self.notificationStatusText = "Provisional"
                @unknown default: self.notificationStatusText = "Unknown"
                }
            }
        }
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[SettingsView] SMAppService error: \(error)")
        }
    }
}

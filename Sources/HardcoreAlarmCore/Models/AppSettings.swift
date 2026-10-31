import Foundation
import SwiftUI

public enum AppTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case dark = "Dark (Recommended)"
    case light = "Light"
    case system = "System"
    
    public var id: String { rawValue }
}

public enum AccentColorTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case cyberRed = "Cyber Red"
    case amberGlow = "Amber Glow"
    case electricBlue = "Electric Blue"
    case emeraldGreen = "Emerald Green"
    case royalViolet = "Royal Violet"
    
    public var id: String { rawValue }
    
    public var color: Color {
        switch self {
        case .cyberRed: return Color(red: 1.0, green: 0.23, blue: 0.23)
        case .amberGlow: return Color(red: 1.0, green: 0.65, blue: 0.15)
        case .electricBlue: return Color(red: 0.15, green: 0.65, blue: 1.0)
        case .emeraldGreen: return Color(red: 0.2, green: 0.85, blue: 0.5)
        case .royalViolet: return Color(red: 0.75, green: 0.35, blue: 1.0)
        }
    }
}

public enum ClockFontStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case digital = "High-Tech Digital"
    case monospace = "Monospace Rounded"
    case minimalist = "Clean Modern"
    
    public var id: String { rawValue }
}

public enum AnimationIntensity: String, Codable, CaseIterable, Identifiable, Sendable {
    case full = "Full & Smooth"
    case reduced = "Reduced Motion"
    
    public var id: String { rawValue }
}

public struct AppSettings: Codable, Equatable, Sendable {
    // Behavior
    public var defaultDifficulty: ChallengeDifficulty
    public var maxChallengeDurationSeconds: Int
    public var globalSnoozeRestricted: Bool
    public var penaltyMultiplier: Double
    public var defaultVerificationEnabled: Bool
    public var defaultVerificationDelayMinutes: Int
    
    // Audio
    public var defaultVolume: Double
    public var defaultRampDuration: TimeInterval
    public var defaultSoundId: String
    public var voiceAnnouncementsEnabled: Bool
    public var spokenVoiceName: String?
    
    // Appearance
    public var theme: AppTheme
    public var accentColor: AccentColorTheme
    public var clockStyle: ClockFontStyle
    public var animationIntensity: AnimationIntensity
    public var compactDashboard: Bool
    
    // Reliability
    public var launchAtLogin: Bool
    public var preventSleepDuringAlarm: Bool
    public var notificationsEnabled: Bool
    
    public init(
        defaultDifficulty: ChallengeDifficulty = .hard,
        maxChallengeDurationSeconds: Int = 300,
        globalSnoozeRestricted: Bool = false,
        penaltyMultiplier: Double = 1.5,
        defaultVerificationEnabled: Bool = true,
        defaultVerificationDelayMinutes: Int = 5,
        defaultVolume: Double = 0.95,
        defaultRampDuration: TimeInterval = 20.0,
        defaultSoundId: String = "emergency_siren",
        voiceAnnouncementsEnabled: Bool = true,
        spokenVoiceName: String? = nil,
        theme: AppTheme = .dark,
        accentColor: AccentColorTheme = .amberGlow,
        clockStyle: ClockFontStyle = .digital,
        animationIntensity: AnimationIntensity = .full,
        compactDashboard: Bool = false,
        launchAtLogin: Bool = false,
        preventSleepDuringAlarm: Bool = true,
        notificationsEnabled: Bool = true
    ) {
        self.defaultDifficulty = defaultDifficulty
        self.maxChallengeDurationSeconds = maxChallengeDurationSeconds
        self.globalSnoozeRestricted = globalSnoozeRestricted
        self.penaltyMultiplier = penaltyMultiplier
        self.defaultVerificationEnabled = defaultVerificationEnabled
        self.defaultVerificationDelayMinutes = defaultVerificationDelayMinutes
        self.defaultVolume = defaultVolume
        self.defaultRampDuration = defaultRampDuration
        self.defaultSoundId = defaultSoundId
        self.voiceAnnouncementsEnabled = voiceAnnouncementsEnabled
        self.spokenVoiceName = spokenVoiceName
        self.theme = theme
        self.accentColor = accentColor
        self.clockStyle = clockStyle
        self.animationIntensity = animationIntensity
        self.compactDashboard = compactDashboard
        self.launchAtLogin = launchAtLogin
        self.preventSleepDuringAlarm = preventSleepDuringAlarm
        self.notificationsEnabled = notificationsEnabled
    }
}

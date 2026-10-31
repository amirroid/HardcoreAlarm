import Foundation

public enum AlarmPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case gentle = "Gentle"
    case normal = "Normal"
    case hardcore = "Hardcore"
    case extreme = "Extreme"
    case impossible = "Impossible"
    case custom = "Custom"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .gentle: return "leaf.fill"
        case .normal: return "sun.max.fill"
        case .hardcore: return "bolt.shield.fill"
        case .extreme: return "flame.fill"
        case .impossible: return "skull.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .gentle: return "Gradual wake-up with light challenge and snooze."
        case .normal: return "Balanced morning routine with moderate challenge."
        case .hardcore: return "Aggressive audio, no snooze, mandatory hard challenges."
        case .extreme: return "Maximum sirens, multi-step pipeline, anti-sleep checks."
        case .impossible: return "Zero-tolerance multi-stage gauntlet for extreme heavy sleepers."
        case .custom: return "Tailored to your specific parameters."
        }
    }
    
    public var defaultSoundId: String {
        switch self {
        case .gentle: return "loud_beep"
        case .normal: return "electronic_warning"
        case .hardcore: return "industrial_klaxon"
        case .extreme: return "emergency_siren"
        case .impossible: return "nuclear_klaxon"
        case .custom: return "emergency_siren"
        }
    }
    
    public var defaultVolume: Double {
        switch self {
        case .gentle: return 0.6
        case .normal: return 0.85
        case .hardcore: return 1.0
        case .extreme: return 1.0
        case .impossible: return 1.0
        case .custom: return 0.9
        }
    }
    
    public var defaultRampDuration: TimeInterval {
        switch self {
        case .gentle: return 60.0
        case .normal: return 30.0
        case .hardcore: return 15.0
        case .extreme: return 5.0
        case .impossible: return 0.0
        case .custom: return 20.0
        }
    }
    
    public var defaultSnoozeAllowed: Bool {
        switch self {
        case .gentle, .normal: return true
        case .hardcore, .extreme, .impossible: return false
        case .custom: return false
        }
    }
    
    public var defaultMaxSnoozes: Int {
        switch self {
        case .gentle: return 2
        case .normal: return 1
        case .hardcore, .extreme, .impossible, .custom: return 0
        }
    }
    
    public var defaultChallenges: [ChallengeConfig] {
        switch self {
        case .gentle:
            return [
                ChallengeConfig(type: .math, difficulty: .easy, questionCount: 2, mistakePenaltyQuestions: 1)
            ]
        case .normal:
            return [
                ChallengeConfig(type: .math, difficulty: .medium, questionCount: 3, mistakePenaltyQuestions: 2)
            ]
        case .hardcore:
            return [
                ChallengeConfig(type: .math, difficulty: .hard, questionCount: 5, mistakePenaltyQuestions: 2),
                ChallengeConfig(type: .memory, difficulty: .medium, questionCount: 5, gridSize: 3)
            ]
        case .extreme:
            return [
                ChallengeConfig(type: .math, difficulty: .insane, questionCount: 6, mistakePenaltyQuestions: 3),
                ChallengeConfig(type: .pattern, difficulty: .hard, questionCount: 2, gridSize: 4),
                ChallengeConfig(type: .typing, difficulty: .hard, questionCount: 1, accuracyRequired: 0.98)
            ]
        case .impossible:
            return [
                ChallengeConfig(type: .math, difficulty: .insane, questionCount: 10, mistakePenaltyQuestions: 4),
                ChallengeConfig(type: .memory, difficulty: .insane, questionCount: 8, gridSize: 4),
                ChallengeConfig(type: .pattern, difficulty: .insane, questionCount: 3, gridSize: 5),
                ChallengeConfig(type: .typing, difficulty: .insane, questionCount: 2, accuracyRequired: 1.0)
            ]
        case .custom:
            return [
                ChallengeConfig(type: .math, difficulty: .medium, questionCount: 3, mistakePenaltyQuestions: 2)
            ]
        }
    }
    
    public var defaultVerificationEnabled: Bool {
        switch self {
        case .gentle: return false
        case .normal: return false
        case .hardcore, .extreme, .impossible: return true
        case .custom: return false
        }
    }
    
    public var defaultVerificationDelayMinutes: Int {
        switch self {
        case .gentle, .normal: return 5
        case .hardcore: return 5
        case .extreme: return 4
        case .impossible: return 3
        case .custom: return 5
        }
    }
    
    public var defaultVerificationStages: Int {
        switch self {
        case .gentle, .normal: return 1
        case .hardcore: return 1
        case .extreme: return 2
        case .impossible: return 3
        case .custom: return 1
        }
    }
}

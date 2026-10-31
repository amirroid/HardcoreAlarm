import Foundation

public enum ChallengeType: String, Codable, CaseIterable, Identifiable, Sendable {
    case math = "Mathematics"
    case memory = "Memory Sequence"
    case typing = "Hardcore Typing"
    case pattern = "Pattern Recognition"
    case multiStep = "Multi-Step Pipeline"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .math: return "function"
        case .memory: return "brain.head.profile"
        case .typing: return "keyboard"
        case .pattern: return "square.grid.3x3.fill"
        case .multiStep: return "flame.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .math:
            return "Solve mental arithmetic problems under pressure. Errors add penalty questions."
        case .memory:
            return "Memorize and accurately reproduce flashing sequence patterns."
        case .typing:
            return "Type complex quotes and tongue-twisters with high accuracy requirement."
        case .pattern:
            return "Memorize a visual matrix configuration and reproduce it exactly."
        case .multiStep:
            return "Chain multiple challenges in sequence. Failure resets progress."
        }
    }
}

public enum ChallengeDifficulty: String, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case insane = "Insane"
    
    public var id: String { rawValue }
    
    public var scoreMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.5
        case .insane: return 4.0
        }
    }
    
    public static func < (lhs: ChallengeDifficulty, rhs: ChallengeDifficulty) -> Bool {
        let order: [ChallengeDifficulty] = [.easy, .medium, .hard, .insane]
        guard let lIndex = order.firstIndex(of: lhs),
              let rIndex = order.firstIndex(of: rhs) else { return false }
        return lIndex < rIndex
    }
}

public struct ChallengeConfig: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var type: ChallengeType
    public var difficulty: ChallengeDifficulty
    public var questionCount: Int
    public var timeLimitSeconds: Int?
    public var mistakePenaltyQuestions: Int
    public var accuracyRequired: Double // 0.0 - 1.0 (for typing)
    public var gridSize: Int // for pattern / memory (e.g. 3 for 3x3, 4 for 4x4)
    
    public init(
        id: UUID = UUID(),
        type: ChallengeType = .math,
        difficulty: ChallengeDifficulty = .medium,
        questionCount: Int = 3,
        timeLimitSeconds: Int? = nil,
        mistakePenaltyQuestions: Int = 2,
        accuracyRequired: Double = 0.95,
        gridSize: Int = 3
    ) {
        self.id = id
        self.type = type
        self.difficulty = difficulty
        self.questionCount = questionCount
        self.timeLimitSeconds = timeLimitSeconds
        self.mistakePenaltyQuestions = mistakePenaltyQuestions
        self.accuracyRequired = accuracyRequired
        self.gridSize = gridSize
    }
    
    public static var defaultMath: ChallengeConfig {
        ChallengeConfig(type: .math, difficulty: .medium, questionCount: 3, mistakePenaltyQuestions: 2)
    }
    
    public static var defaultMemory: ChallengeConfig {
        ChallengeConfig(type: .memory, difficulty: .medium, questionCount: 5, gridSize: 3)
    }
    
    public static var defaultTyping: ChallengeConfig {
        ChallengeConfig(type: .typing, difficulty: .medium, questionCount: 1, accuracyRequired: 0.95)
    }
    
    public static var defaultPattern: ChallengeConfig {
        ChallengeConfig(type: .pattern, difficulty: .medium, questionCount: 1, gridSize: 4)
    }
}

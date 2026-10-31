import Foundation

public struct AlarmHistoryRecord: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var alarmId: UUID
    public var alarmTitle: String
    public var scheduledTime: Date
    public var firedTime: Date
    public var dismissedTime: Date?
    public var wasSuccessful: Bool
    public var wasDismissedViaChallenge: Bool
    public var solveDurationSeconds: TimeInterval
    public var snoozesUsed: Int
    public var mistakeCount: Int
    public var challengesCompleted: [ChallengeType]
    public var verificationStatus: VerificationOutcome
    public var difficulty: ChallengeDifficulty
    
    public enum VerificationOutcome: String, Codable, Sendable {
        case notApplicable = "N/A"
        case pending = "Pending"
        case passed = "Verified Awake"
        case missed = "Missed (Re-alarmed)"
    }
    
    public init(
        id: UUID = UUID(),
        alarmId: UUID,
        alarmTitle: String,
        scheduledTime: Date,
        firedTime: Date = Date(),
        dismissedTime: Date? = nil,
        wasSuccessful: Bool = true,
        wasDismissedViaChallenge: Bool = true,
        solveDurationSeconds: TimeInterval = 0,
        snoozesUsed: Int = 0,
        mistakeCount: Int = 0,
        challengesCompleted: [ChallengeType] = [],
        verificationStatus: VerificationOutcome = .notApplicable,
        difficulty: ChallengeDifficulty = .medium
    ) {
        self.id = id
        self.alarmId = alarmId
        self.alarmTitle = alarmTitle
        self.scheduledTime = scheduledTime
        self.firedTime = firedTime
        self.dismissedTime = dismissedTime
        self.wasSuccessful = wasSuccessful
        self.wasDismissedViaChallenge = wasDismissedViaChallenge
        self.solveDurationSeconds = solveDurationSeconds
        self.snoozesUsed = snoozesUsed
        self.mistakeCount = mistakeCount
        self.challengesCompleted = challengesCompleted
        self.verificationStatus = verificationStatus
        self.difficulty = difficulty
    }
}

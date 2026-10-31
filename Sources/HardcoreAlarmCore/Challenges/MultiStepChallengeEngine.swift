import Foundation

public final class MultiStepChallengeEngine: ObservableObject, @unchecked Sendable {
    @Published public private(set) var currentStepIndex: Int = 0
    @Published public private(set) var totalMistakes: Int = 0
    @Published public private(set) var isAllCompleted: Bool = false
    @Published public private(set) var completedTypes: [ChallengeType] = []
    
    public let challenges: [ChallengeConfig]
    public let startTime: Date
    
    public init(challenges: [ChallengeConfig]) {
        self.challenges = challenges.isEmpty ? [ChallengeConfig.defaultMath] : challenges
        self.startTime = Date()
    }
    
    public var currentChallenge: ChallengeConfig {
        guard currentStepIndex < challenges.count else { return challenges[0] }
        return challenges[currentStepIndex]
    }
    
    public var totalSteps: Int {
        challenges.count
    }
    
    public func recordMistake() {
        totalMistakes += 1
    }
    
    public func completeCurrentStep() {
        completedTypes.append(currentChallenge.type)
        let nextIndex = currentStepIndex + 1
        if nextIndex >= challenges.count {
            isAllCompleted = true
        } else {
            currentStepIndex = nextIndex
        }
    }
    
    public var totalElapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

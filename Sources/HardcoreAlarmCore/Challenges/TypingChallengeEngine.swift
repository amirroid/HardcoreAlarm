import Foundation

public final class TypingChallengeEngine: ObservableObject, @unchecked Sendable {
    @Published public private(set) var targetText: String = ""
    @Published public var currentInput: String = "" {
        didSet {
            validateInput()
        }
    }
    @Published public private(set) var accuracy: Double = 1.0
    @Published public private(set) var wordsPerMinute: Double = 0.0
    @Published public private(set) var isCompleted: Bool = false
    @Published public private(set) var mistakeCount: Int = 0
    @Published public private(set) var matchedIndex: Int = 0
    
    public let accuracyRequired: Double
    private let config: ChallengeConfig
    private var startTime: Date?
    
    private static let quotes: [ChallengeDifficulty: [String]] = [
        .easy: [
            "The morning sun never waits for those who linger in bed.",
            "Wake up with determination and sleep with genuine satisfaction.",
            "Today is an opportunity to build the tomorrow you envision."
        ],
        .medium: [
            "Discipline is choosing between what you want now and what you want most.",
            "To conquer without risk is to triumph without glory. Stand up and conquer the day.",
            "Heavy eyelids will not build the future you desire. Take immediate action."
        ],
        .hard: [
            "Cognitive clarity requires overcoming biological resistance. Wakefulness is an act of will.",
            "The impediment to action advances action. What stands in the way becomes the way forward.",
            "Relentless perseverance through dawn fractures exhaustion and creates unyielding strength."
        ],
        .insane: [
            "Six sick hicks nick six slick bricks with picks and sticks while synchronized sirens scream violently.",
            "Oscillating synaptic thresholds mandate instantaneous physiological activation; slumber is permanently terminated.",
            "Neurological alertness demands unwavering cognitive focus under extreme auditory pressure: rise and dominate."
        ]
    ]
    
    public init(config: ChallengeConfig) {
        self.config = config
        self.accuracyRequired = config.accuracyRequired
        loadQuote()
    }
    
    public func loadQuote() {
        let pool = Self.quotes[config.difficulty] ?? Self.quotes[.medium]!
        targetText = pool.randomElement() ?? pool[0]
        currentInput = ""
        accuracy = 1.0
        wordsPerMinute = 0.0
        isCompleted = false
        mistakeCount = 0
        matchedIndex = 0
        startTime = nil
    }
    
    private func validateInput() {
        if startTime == nil && !currentInput.isEmpty {
            startTime = Date()
        }
        
        let targetChars = Array(targetText)
        let inputChars = Array(currentInput)
        
        var matches = 0
        var errors = 0
        
        for i in 0..<min(targetChars.count, inputChars.count) {
            if targetChars[i] == inputChars[i] {
                matches += 1
            } else {
                errors += 1
            }
        }
        
        if inputChars.count > targetChars.count {
            errors += (inputChars.count - targetChars.count)
        }
        
        matchedIndex = matches
        mistakeCount = errors
        
        let totalTyped = max(1, inputChars.count)
        accuracy = max(0.0, Double(totalTyped - errors) / Double(totalTyped))
        
        if let start = startTime {
            let elapsedMin = max(0.01, Date().timeIntervalSince(start) / 60.0)
            let words = Double(matches) / 5.0
            wordsPerMinute = words / elapsedMin
        }
        
        // Completion condition
        if inputChars.count >= targetChars.count && accuracy >= accuracyRequired && currentInput.trimmingCharacters(in: .whitespaces) == targetText.trimmingCharacters(in: .whitespaces) {
            isCompleted = true
        }
    }
}

import Foundation

public final class PatternChallengeEngine: ObservableObject, @unchecked Sendable {
    public enum State: Equatable, Sendable {
        case previewing(secondsRemaining: Double)
        case recalling
        case mistakePenalty
        case completed
    }
    
    @Published public private(set) var state: State = .previewing(secondsRemaining: 3.5)
    @Published public private(set) var activePattern: Set<Int> = []
    @Published public private(set) var selectedCells: Set<Int> = []
    @Published public private(set) var mistakesCount: Int = 0
    @Published public private(set) var patternsCompleted: Int = 0
    @Published public private(set) var patternsRequired: Int
    
    public let gridSize: Int
    private let config: ChallengeConfig
    private var countdownTimer: Timer?
    
    public init(config: ChallengeConfig) {
        self.config = config
        self.gridSize = config.gridSize > 0 ? config.gridSize : 4
        self.patternsRequired = config.questionCount
        generateNewPattern()
    }
    
    public func startChallenge() {
        startPreview()
    }
    
    public func generateNewPattern() {
        selectedCells.removeAll()
        let totalCells = gridSize * gridSize
        
        let cellCount: Int
        switch config.difficulty {
        case .easy: cellCount = max(3, totalCells / 4)
        case .medium: cellCount = max(5, totalCells / 3)
        case .hard: cellCount = max(7, totalCells / 2)
        case .insane: cellCount = max(9, (totalCells * 3) / 5)
        }
        
        var generated = Set<Int>()
        while generated.count < cellCount {
            generated.insert(Int.random(in: 0..<totalCells))
        }
        activePattern = generated
    }
    
    private var previewSecondsRemaining: Double = 3.5
    
    public func startPreview() {
        countdownTimer?.invalidate()
        selectedCells.removeAll()
        
        previewSecondsRemaining = 3.5
        state = .previewing(secondsRemaining: previewSecondsRemaining)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.previewSecondsRemaining -= 0.1
            if self.previewSecondsRemaining <= 0 {
                timer.invalidate()
                self.countdownTimer = nil
                self.state = .recalling
            } else {
                self.state = .previewing(secondsRemaining: self.previewSecondsRemaining)
            }
        }
    }
    
    public func toggleCell(_ index: Int) {
        guard case .recalling = state else { return }
        
        if selectedCells.contains(index) {
            selectedCells.remove(index)
        } else {
            selectedCells.insert(index)
        }
    }
    
    public func submitSelection() -> Bool {
        guard case .recalling = state else { return false }
        
        if selectedCells == activePattern {
            patternsCompleted += 1
            if patternsCompleted >= patternsRequired {
                state = .completed
            } else {
                generateNewPattern()
                startPreview()
            }
            return true
        } else {
            mistakesCount += 1
            state = .mistakePenalty
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                guard let self = self else { return }
                self.generateNewPattern()
                self.startPreview()
            }
            return false
        }
    }
    
    public func stop() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}

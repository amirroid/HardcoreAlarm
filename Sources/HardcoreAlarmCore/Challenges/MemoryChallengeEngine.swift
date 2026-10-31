import Foundation

public final class MemoryChallengeEngine: ObservableObject, @unchecked Sendable {
    public enum State: Equatable, Sendable {
        case ready
        case showingSequence(activeStep: Int)
        case waitingForInput(currentStep: Int)
        case errorPenalty
        case completed
    }
    
    @Published public private(set) var state: State = .ready
    @Published public private(set) var sequence: [Int] = []
    @Published public private(set) var userInputs: [Int] = []
    @Published public private(set) var activeHighlightedTile: Int? = nil
    @Published public private(set) var mistakesCount: Int = 0
    @Published public private(set) var sequenceLength: Int
    
    public let gridSize: Int
    private let config: ChallengeConfig
    private var playbackTimer: Timer?
    
    public init(config: ChallengeConfig) {
        self.config = config
        self.gridSize = config.gridSize > 0 ? config.gridSize : 3
        
        switch config.difficulty {
        case .easy: self.sequenceLength = 4
        case .medium: self.sequenceLength = 6
        case .hard: self.sequenceLength = 8
        case .insane: self.sequenceLength = 10
        }
        
        generateSequence()
    }
    
    public func startChallenge() {
        playSequence()
    }
    
    public func generateSequence() {
        let totalTiles = gridSize * gridSize
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<totalTiles) }
        userInputs.removeAll()
        activeHighlightedTile = nil
    }
    
    private var playbackStep: Int = 0
    
    public func playSequence() {
        playbackTimer?.invalidate()
        userInputs.removeAll()
        activeHighlightedTile = nil
        
        playbackStep = 0
        state = .showingSequence(activeStep: 0)
        
        let stepSpeed = config.difficulty == .insane ? 0.45 : 0.65
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: stepSpeed, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let current = self.playbackStep
            if current < self.sequence.count {
                self.activeHighlightedTile = self.sequence[current]
                self.state = .showingSequence(activeStep: current)
                
                // Clear highlight briefly before next step
                DispatchQueue.main.asyncAfter(deadline: .now() + (stepSpeed * 0.75)) { [weak self] in
                    if self?.state == .showingSequence(activeStep: current) {
                        self?.activeHighlightedTile = nil
                    }
                }
                
                self.playbackStep += 1
            } else {
                timer.invalidate()
                self.playbackTimer = nil
                self.activeHighlightedTile = nil
                self.state = .waitingForInput(currentStep: 0)
            }
        }
    }
    
    public func inputTile(_ tileIndex: Int) -> Bool {
        guard case .waitingForInput(let currentStep) = state else { return false }
        
        activeHighlightedTile = tileIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            if self?.activeHighlightedTile == tileIndex {
                self?.activeHighlightedTile = nil
            }
        }
        
        if sequence[currentStep] == tileIndex {
            userInputs.append(tileIndex)
            let nextStep = currentStep + 1
            
            if nextStep >= sequence.count {
                state = .completed
                return true
            } else {
                state = .waitingForInput(currentStep: nextStep)
                return true
            }
        } else {
            // Mistake made
            mistakesCount += 1
            state = .errorPenalty
            
            // If insane/hard, extend sequence length!
            if config.difficulty >= .hard {
                sequenceLength += 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.generateSequence()
                self.playSequence()
            }
            return false
        }
    }
    
    public func stop() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

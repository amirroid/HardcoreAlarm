import Foundation

public struct MathProblem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let expression: String
    public let solution: Int
    
    public init(id: UUID = UUID(), expression: String, solution: Int) {
        self.id = id
        self.expression = expression
        self.solution = solution
    }
}

public final class MathChallengeEngine: ObservableObject, @unchecked Sendable {
    @Published public private(set) var currentProblem: MathProblem?
    @Published public private(set) var questionsCompleted: Int = 0
    @Published public private(set) var totalQuestionsRequired: Int
    @Published public private(set) var mistakesCount: Int = 0
    @Published public private(set) var isCompleted: Bool = false
    @Published public private(set) var lastMistakePenaltyApplied: Int = 0
    
    private let config: ChallengeConfig
    
    public init(config: ChallengeConfig) {
        self.config = config
        self.totalQuestionsRequired = config.questionCount
        nextProblem()
    }
    
    public func submitAnswer(_ answer: Int) -> Bool {
        guard let problem = currentProblem else { return false }
        
        if answer == problem.solution {
            questionsCompleted += 1
            if questionsCompleted >= totalQuestionsRequired {
                isCompleted = true
                currentProblem = nil
            } else {
                nextProblem()
            }
            return true
        } else {
            mistakesCount += 1
            let penalty = config.mistakePenaltyQuestions
            totalQuestionsRequired += penalty
            lastMistakePenaltyApplied = penalty
            // Generate a fresh problem so user can't just brute force
            nextProblem()
            return false
        }
    }
    
    public func reset() {
        questionsCompleted = 0
        mistakesCount = 0
        totalQuestionsRequired = config.questionCount
        isCompleted = false
        lastMistakePenaltyApplied = 0
        nextProblem()
    }
    
    private func nextProblem() {
        currentProblem = Self.generateProblem(difficulty: config.difficulty)
    }
    
    // MARK: - Problem Generator
    public static func generateProblem(difficulty: ChallengeDifficulty) -> MathProblem {
        switch difficulty {
        case .easy:
            // 2-digit addition or subtraction
            let isAdd = Bool.random()
            if isAdd {
                let a = Int.random(in: 12...89)
                let b = Int.random(in: 11...75)
                return MathProblem(expression: "\(a) + \(b)", solution: a + b)
            } else {
                let a = Int.random(in: 35...99)
                let b = Int.random(in: 12...a - 5)
                return MathProblem(expression: "\(a) - \(b)", solution: a - b)
            }
            
        case .medium:
            // Multiplication or division or 3-term addition/subtraction
            let op = Int.random(in: 0...2)
            if op == 0 {
                let a = Int.random(in: 6...19)
                let b = Int.random(in: 4...16)
                return MathProblem(expression: "\(a) × \(b)", solution: a * b)
            } else if op == 1 {
                let divisor = Int.random(in: 4...15)
                let quotient = Int.random(in: 6...20)
                let dividend = divisor * quotient
                return MathProblem(expression: "\(dividend) ÷ \(divisor)", solution: quotient)
            } else {
                let a = Int.random(in: 25...85)
                let b = Int.random(in: 15...65)
                let c = Int.random(in: 10...45)
                return MathProblem(expression: "\(a) + \(b) - \(c)", solution: a + b - c)
            }
            
        case .hard:
            // Multi-step: (a × b) ± c or (a ÷ b) + c or a + b × c
            let style = Int.random(in: 0...2)
            if style == 0 {
                let a = Int.random(in: 7...25)
                let b = Int.random(in: 6...18)
                let c = Int.random(in: 15...95)
                let isAdd = Bool.random()
                if isAdd {
                    return MathProblem(expression: "(\(a) × \(b)) + \(c)", solution: (a * b) + c)
                } else {
                    return MathProblem(expression: "(\(a) × \(b)) - \(c)", solution: (a * b) - c)
                }
            } else if style == 1 {
                let divisor = Int.random(in: 6...16)
                let quotient = Int.random(in: 8...24)
                let dividend = divisor * quotient
                let c = Int.random(in: 25...120)
                return MathProblem(expression: "(\(dividend) ÷ \(divisor)) + \(c)", solution: quotient + c)
            } else {
                let a = Int.random(in: 30...90)
                let b = Int.random(in: 6...15)
                let c = Int.random(in: 4...12)
                return MathProblem(expression: "\(a) + (\(b) × \(c))", solution: a + (b * c))
            }
            
        case .insane:
            // Multi-step nested arithmetic: (a × b) - (c × d) + e
            let opStyle = Int.random(in: 0...2)
            if opStyle == 0 {
                let a = Int.random(in: 12...35)
                let b = Int.random(in: 8...22)
                let c = Int.random(in: 4...12)
                let d = Int.random(in: 5...15)
                let expr = "(\(a) × \(b)) - (\(c) × \(d))"
                return MathProblem(expression: expr, solution: (a * b) - (c * d))
            } else if opStyle == 1 {
                let div = Int.random(in: 7...18)
                let quot = Int.random(in: 12...35)
                let dividend = div * quot
                let mulA = Int.random(in: 14...28)
                let mulB = Int.random(in: 6...14)
                let expr = "(\(mulA) × \(mulB)) + (\(dividend) ÷ \(div))"
                return MathProblem(expression: expr, solution: (mulA * mulB) + quot)
            } else {
                let a = Int.random(in: 18...45)
                let b = Int.random(in: 7...16)
                let c = Int.random(in: 55...195)
                let d = Int.random(in: 20...80)
                let expr = "(\(a) × \(b)) - \(c) + \(d)"
                return MathProblem(expression: expr, solution: (a * b) - c + d)
            }
        }
    }
}

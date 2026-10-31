import XCTest
@testable import HardcoreAlarmCore

final class MathChallengeTests: XCTestCase {
    func testProblemGenerationAcrossDifficulties() {
        for diff in ChallengeDifficulty.allCases {
            let problem = MathChallengeEngine.generateProblem(difficulty: diff)
            XCTAssertFalse(problem.expression.isEmpty)
            // Verify solution is not infinite or NaN
            XCTAssertTrue(problem.solution > -100000 && problem.solution < 100000)
        }
    }
    
    func testMathEngineSuccessFlow() {
        let config = ChallengeConfig(type: .math, difficulty: .easy, questionCount: 2, mistakePenaltyQuestions: 1)
        let engine = MathChallengeEngine(config: config)
        
        XCTAssertEqual(engine.questionsCompleted, 0)
        XCTAssertFalse(engine.isCompleted)
        
        // Correct answer for problem 1
        let p1 = engine.currentProblem!
        let success1 = engine.submitAnswer(p1.solution)
        XCTAssertTrue(success1)
        XCTAssertEqual(engine.questionsCompleted, 1)
        XCTAssertFalse(engine.isCompleted)
        
        // Correct answer for problem 2
        let p2 = engine.currentProblem!
        let success2 = engine.submitAnswer(p2.solution)
        XCTAssertTrue(success2)
        XCTAssertEqual(engine.questionsCompleted, 2)
        XCTAssertTrue(engine.isCompleted)
    }
    
    func testMathEngineMistakePenalty() {
        let config = ChallengeConfig(type: .math, difficulty: .medium, questionCount: 3, mistakePenaltyQuestions: 2)
        let engine = MathChallengeEngine(config: config)
        
        let initialRequired = engine.totalQuestionsRequired
        XCTAssertEqual(initialRequired, 3)
        
        let wrongAnswer = (engine.currentProblem?.solution ?? 0) + 999
        let success = engine.submitAnswer(wrongAnswer)
        
        XCTAssertFalse(success)
        XCTAssertEqual(engine.mistakesCount, 1)
        XCTAssertEqual(engine.totalQuestionsRequired, 5) // 3 + 2 penalty!
        XCTAssertFalse(engine.isCompleted)
    }
}

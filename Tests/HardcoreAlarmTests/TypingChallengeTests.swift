import XCTest
@testable import HardcoreAlarmCore

final class TypingChallengeTests: XCTestCase {
    func testTypingAccuracyCalculation() {
        let config = ChallengeConfig(type: .typing, difficulty: .easy, accuracyRequired: 0.95)
        let engine = TypingChallengeEngine(config: config)
        
        XCTAssertFalse(engine.targetText.isEmpty)
        
        // Exact typing match
        engine.currentInput = engine.targetText
        XCTAssertEqual(engine.accuracy, 1.0)
        XCTAssertTrue(engine.isCompleted)
    }
    
    func testTypingWithTypoRequiresFixing() {
        let config = ChallengeConfig(type: .typing, difficulty: .easy, accuracyRequired: 1.0)
        let engine = TypingChallengeEngine(config: config)
        
        // Introduce a typo at the start
        engine.currentInput = "X" + String(engine.targetText.dropFirst())
        XCTAssertFalse(engine.isCompleted)
        XCTAssertTrue(engine.mistakeCount > 0)
    }
}

import XCTest
@testable import HardcoreAlarmCore

final class MemoryChallengeTests: XCTestCase {
    func testMemorySequenceLengthByDifficulty() {
        let easyConfig = ChallengeConfig(type: .memory, difficulty: .easy, gridSize: 3)
        let easyEngine = MemoryChallengeEngine(config: easyConfig)
        XCTAssertEqual(easyEngine.sequenceLength, 4)
        XCTAssertEqual(easyEngine.sequence.count, 4)
        
        let insaneConfig = ChallengeConfig(type: .memory, difficulty: .insane, gridSize: 4)
        let insaneEngine = MemoryChallengeEngine(config: insaneConfig)
        XCTAssertEqual(insaneEngine.sequenceLength, 10)
        XCTAssertEqual(insaneEngine.sequence.count, 10)
    }
    
    func testMemorySequenceTilesWithinGridBounds() {
        let config = ChallengeConfig(type: .memory, difficulty: .hard, gridSize: 3)
        let engine = MemoryChallengeEngine(config: config)
        let maxTileIndex = config.gridSize * config.gridSize
        
        for tile in engine.sequence {
            XCTAssertTrue(tile >= 0 && tile < maxTileIndex)
        }
    }
}

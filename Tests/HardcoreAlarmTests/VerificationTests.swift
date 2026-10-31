import XCTest
@testable import HardcoreAlarmCore

final class VerificationTests: XCTestCase {
    func testVerificationStatusTransitions() {
        let manager = WakeUpVerificationManager.shared
        manager.reset()
        XCTAssertEqual(manager.status, .idle)
        
        var alarm = Alarm(
            title: "Verification Test Alarm",
            hour: 7,
            minute: 0,
            wakeUpVerification: WakeUpVerificationConfig(isEnabled: true, delayMinutes: 5, stagesCount: 2)
        )
        
        manager.startVerification(for: alarm)
        
        if case .pending(let title, let secondsRemaining, let stage, let total) = manager.status {
            XCTAssertEqual(title, "Verification Test Alarm")
            XCTAssertEqual(stage, 1)
            XCTAssertEqual(total, 2)
            XCTAssertEqual(secondsRemaining, 300) // 5 minutes * 60s
        } else {
            XCTFail("Manager should be in pending state")
        }
        
        manager.reset()
        XCTAssertEqual(manager.status, .idle)
    }
}

import Foundation
import IOKit
import IOKit.pwr_mgt

public final class PowerManager: @unchecked Sendable {
    public static let shared = PowerManager()
    
    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0
    private var hasActiveAssertion: Bool = false
    private let lock = NSLock()
    
    public init() {}
    
    public func activateWakeLock(reason: String = "Hardcore Alarm Triggered") {
        lock.lock()
        defer { lock.unlock() }
        
        guard !hasActiveAssertion else { return }
        
        // Prevent display sleep
        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &displayAssertionID
        )
        
        // Prevent system sleep
        let systemResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &systemAssertionID
        )
        
        if displayResult == kIOReturnSuccess && systemResult == kIOReturnSuccess {
            hasActiveAssertion = true
            print("[PowerManager] Successfully activated display and system wake assertions.")
        } else {
            print("[PowerManager] Warning: IOPMAssertion returned non-zero code. (display: \(displayResult), system: \(systemResult))")
        }
    }
    
    public func releaseWakeLock() {
        lock.lock()
        defer { lock.unlock() }
        
        guard hasActiveAssertion else { return }
        
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }
        hasActiveAssertion = false
        print("[PowerManager] Released wake assertions.")
    }
}

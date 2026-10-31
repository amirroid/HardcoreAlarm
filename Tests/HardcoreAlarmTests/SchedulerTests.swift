import XCTest
@testable import HardcoreAlarmCore

final class SchedulerTests: XCTestCase {
    func testOneTimeAlarmCalculation() {
        let scheduler = AlarmScheduler.shared
        let now = Date()
        let cal = Calendar.current
        
        // Alarm set for 2 hours in the future
        let targetDate = cal.date(byAdding: .hour, value: 2, to: now)!
        let h = cal.component(.hour, from: targetDate)
        let m = cal.component(.minute, from: targetDate)
        
        let alarm = Alarm(
            hour: h,
            minute: m,
            isEnabled: true,
            repeatDays: [] // One-time
        )
        
        let nextFire = scheduler.calculateNextFireDate(for: alarm, relativeTo: now)
        XCTAssertNotNil(nextFire)
        XCTAssertTrue(nextFire! > now)
        XCTAssertEqual(cal.component(.hour, from: nextFire!), h)
        XCTAssertEqual(cal.component(.minute, from: nextFire!), m)
    }
    
    func testDisabledAlarmReturnsNil() {
        let scheduler = AlarmScheduler.shared
        let alarm = Alarm(hour: 7, minute: 0, isEnabled: false)
        let nextFire = scheduler.calculateNextFireDate(for: alarm)
        XCTAssertNil(nextFire)
    }
    
    func testSkipNextOccurrenceAdvancesSchedule() {
        let scheduler = AlarmScheduler.shared
        let now = Date()
        let cal = Calendar.current
        
        let alarmWithoutSkip = Alarm(
            hour: 7,
            minute: 0,
            isEnabled: true,
            repeatDays: Weekday.all,
            skipNextOccurrence: false
        )
        
        let alarmWithSkip = Alarm(
            hour: 7,
            minute: 0,
            isEnabled: true,
            repeatDays: Weekday.all,
            skipNextOccurrence: true
        )
        
        let fire1 = scheduler.calculateNextFireDate(for: alarmWithoutSkip, relativeTo: now)
        let fire2 = scheduler.calculateNextFireDate(for: alarmWithSkip, relativeTo: now)
        
        XCTAssertNotNil(fire1)
        XCTAssertNotNil(fire2)
        XCTAssertTrue(fire2! > fire1!, "Skipping next occurrence should push the fire date forward")
    }
}

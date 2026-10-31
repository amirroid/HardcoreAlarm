import Foundation
import AppKit
import Combine

public final class AlarmScheduler: ObservableObject, @unchecked Sendable {
    public static let shared = AlarmScheduler()
    
    @Published public private(set) var alarms: [Alarm] = []
    @Published public private(set) var nextUpcomingAlarm: Alarm?
    @Published public private(set) var nextFireDate: Date?
    @Published public private(set) var timeUntilNextAlarm: TimeInterval?
    @Published public private(set) var activeRingingAlarm: Alarm?
    
    private var timer: Timer?
    private var sleepCheckTimestamp: Date?
    private let calendar = Calendar.current
    
    public var onAlarmTriggered: ((Alarm) -> Void)?
    
    public init() {
        self.alarms = PersistenceService.shared.loadAlarms()
        setupSleepWakeObservers()
        recalculateNextAlarm()
        startTimer()
    }
    
    // MARK: - Alarms Management
    public func updateAlarms(_ newAlarms: [Alarm]) {
        self.alarms = newAlarms
        PersistenceService.shared.saveAlarms(newAlarms)
        recalculateNextAlarm()
    }
    
    public func addAlarm(_ alarm: Alarm) {
        var list = alarms
        list.append(alarm)
        updateAlarms(list)
    }
    
    public func removeAlarm(id: UUID) {
        var list = alarms
        list.removeAll { $0.id == id }
        updateAlarms(list)
    }
    
    public func toggleAlarm(id: UUID) {
        var list = alarms
        if let idx = list.firstIndex(where: { $0.id == id }) {
            list[idx].isEnabled.toggle()
            updateAlarms(list)
        }
    }
    
    public func duplicateAlarm(id: UUID) {
        guard let existing = alarms.first(where: { $0.id == id }) else { return }
        var duplicate = existing
        duplicate.id = UUID()
        duplicate.title = "\(existing.title) (Copy)"
        addAlarm(duplicate)
    }
    
    public func skipNextOccurrence(id: UUID) {
        var list = alarms
        if let idx = list.firstIndex(where: { $0.id == id }) {
            list[idx].skipNextOccurrence = true
            updateAlarms(list)
        }
    }
    
    // MARK: - Timer & Trigger Loop
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        let now = Date()
        
        // Update live countdown
        if let fireDate = nextFireDate {
            let remaining = fireDate.timeIntervalSince(now)
            timeUntilNextAlarm = max(0, remaining)
            
            // Check if alarm is due (within 1 second window)
            if remaining <= 0.5 && remaining >= -2.0, let dueAlarm = nextUpcomingAlarm {
                triggerAlarm(dueAlarm)
            }
        }
    }
    
    public func triggerAlarm(_ alarm: Alarm) {
        guard activeRingingAlarm == nil else { return } // Already ringing
        
        activeRingingAlarm = alarm
        print("[AlarmScheduler] 🚨 Alarm Triggered: \(alarm.title) at \(Date())")
        
        // If alarm was set to skip next occurrence, clear it now
        if alarm.skipNextOccurrence {
            var list = alarms
            if let idx = list.firstIndex(where: { $0.id == alarm.id }) {
                list[idx].skipNextOccurrence = false
                updateAlarms(list)
            }
        }
        
        // If alarm is a one-time alarm without repeat, disable it after firing
        if alarm.repeatDays.isEmpty && alarm.specificDate == nil {
            var list = alarms
            if let idx = list.firstIndex(where: { $0.id == alarm.id }) {
                list[idx].isEnabled = false
                updateAlarms(list)
            }
        }
        
        onAlarmTriggered?(alarm)
        recalculateNextAlarm()
    }
    
    public func dismissActiveAlarm() {
        activeRingingAlarm = nil
        recalculateNextAlarm()
    }
    
    // MARK: - Next Fire Date Calculation
    public func recalculateNextAlarm() {
        let now = Date()
        var earliestDate: Date? = nil
        var earliestAlarm: Alarm? = nil
        
        for alarm in alarms where alarm.isEnabled {
            if let fireDate = calculateNextFireDate(for: alarm, relativeTo: now) {
                if earliestDate == nil || fireDate < earliestDate! {
                    earliestDate = fireDate
                    earliestAlarm = alarm
                }
            }
        }
        
        self.nextFireDate = earliestDate
        self.nextUpcomingAlarm = earliestAlarm
        
        if let fireDate = earliestDate {
            self.timeUntilNextAlarm = max(0, fireDate.timeIntervalSince(now))
        } else {
            self.timeUntilNextAlarm = nil
        }
    }
    
    public func calculateNextFireDate(for alarm: Alarm, relativeTo referenceDate: Date = Date()) -> Date? {
        guard alarm.isEnabled else { return nil }
        
        // Check date bounds
        if let end = alarm.endDate, referenceDate > end {
            return nil
        }
        
        let startSearchDate: Date
        if let start = alarm.startDate, referenceDate < start {
            startSearchDate = start
        } else {
            startSearchDate = referenceDate
        }
        
        // 1. Specific Date Alarm
        if let specificDate = alarm.specificDate {
            var comp = calendar.dateComponents([.year, .month, .day], from: specificDate)
            comp.hour = alarm.hour
            comp.minute = alarm.minute
            comp.second = 0
            if let date = calendar.date(from: comp), date > referenceDate {
                return date
            }
            return nil
        }
        
        // 2. Weekday Repeating Alarms
        if !alarm.repeatDays.isEmpty {
            var searchDayOffset = 0
            var candidateDates: [Date] = []
            
            // Check up to 14 days ahead to find next active day (or next-next if skip is active)
            while searchDayOffset < 14 {
                guard let targetDay = calendar.date(byAdding: .day, value: searchDayOffset, to: startSearchDate) else { break }
                let weekdayVal = calendar.component(.weekday, from: targetDay)
                
                if let weekday = Weekday(rawValue: weekdayVal), alarm.repeatDays.contains(weekday) {
                    var comp = calendar.dateComponents([.year, .month, .day], from: targetDay)
                    comp.hour = alarm.hour
                    comp.minute = alarm.minute
                    comp.second = 0
                    
                    if let fireDate = calendar.date(from: comp), fireDate > referenceDate {
                        candidateDates.append(fireDate)
                        if candidateDates.count >= 2 { break }
                    }
                }
                searchDayOffset += 1
            }
            
            if alarm.skipNextOccurrence && candidateDates.count > 1 {
                return candidateDates[1]
            }
            return candidateDates.first
        }
        
        // 3. One-time Alarm (Today or Tomorrow)
        var comp = calendar.dateComponents([.year, .month, .day], from: startSearchDate)
        comp.hour = alarm.hour
        comp.minute = alarm.minute
        comp.second = 0
        
        if let todayTarget = calendar.date(from: comp) {
            if todayTarget > referenceDate {
                return todayTarget
            } else if let tomorrowTarget = calendar.date(byAdding: .day, value: 1, to: todayTarget) {
                return tomorrowTarget
            }
        }
        
        return nil
    }
    
    // MARK: - Sleep & Wake Handling
    private func setupSleepWakeObservers() {
        let center = NSWorkspace.shared.notificationCenter
        
        center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sleepCheckTimestamp = Date()
            print("[AlarmScheduler] System will sleep at \(Date())")
        }
        
        center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("[AlarmScheduler] System woke up at \(Date())")
            let now = Date()
            
            // If an alarm was scheduled between sleep and wake, trigger it immediately!
            if let sleepTime = self.sleepCheckTimestamp, let fireDate = self.nextFireDate, let alarm = self.nextUpcomingAlarm {
                if fireDate >= sleepTime && fireDate <= now {
                    print("[AlarmScheduler] Alarm \(alarm.title) was missed during sleep! Triggering immediately on wake!")
                    self.triggerAlarm(alarm)
                }
            }
            self.sleepCheckTimestamp = nil
            self.recalculateNextAlarm()
        }
    }
}

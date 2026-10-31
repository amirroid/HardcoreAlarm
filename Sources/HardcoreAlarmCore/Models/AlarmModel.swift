import Foundation

public enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    public var id: Int { rawValue }
    
    public var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
    
    public var fullName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
    
    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        // Monday-first ordering
        let lhsOrder = lhs == .sunday ? 7 : lhs.rawValue - 1
        let rhsOrder = rhs == .sunday ? 7 : rhs.rawValue - 1
        return lhsOrder < rhsOrder
    }
    
    public static var all: Set<Weekday> {
        Set(Weekday.allCases)
    }
    
    public static var weekdaysOnly: Set<Weekday> {
        [.monday, .tuesday, .wednesday, .thursday, .friday]
    }
    
    public static var weekendsOnly: Set<Weekday> {
        [.saturday, .sunday]
    }
}

public struct SnoozeConfig: Codable, Equatable, Hashable, Sendable {
    public var isEnabled: Bool
    public var durationMinutes: Int
    public var maxCount: Int
    public var remainingCount: Int
    
    public init(
        isEnabled: Bool = false,
        durationMinutes: Int = 5,
        maxCount: Int = 1,
        remainingCount: Int = 1
    ) {
        self.isEnabled = isEnabled
        self.durationMinutes = durationMinutes
        self.maxCount = maxCount
        self.remainingCount = remainingCount
    }
}

public struct WakeUpVerificationConfig: Codable, Equatable, Hashable, Sendable {
    public var isEnabled: Bool
    public var delayMinutes: Int
    public var stagesCount: Int
    public var penaltyReAlarmSound: String
    
    public init(
        isEnabled: Bool = false,
        delayMinutes: Int = 5,
        stagesCount: Int = 1,
        penaltyReAlarmSound: String = "nuclear_klaxon"
    ) {
        self.isEnabled = isEnabled
        self.delayMinutes = delayMinutes
        self.stagesCount = stagesCount
        self.penaltyReAlarmSound = penaltyReAlarmSound
    }
}

public struct Alarm: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var details: String
    public var hour: Int // 0 - 23
    public var minute: Int // 0 - 59
    public var isEnabled: Bool
    public var repeatDays: Set<Weekday>
    public var specificDate: Date?
    public var startDate: Date?
    public var endDate: Date?
    
    // Audio configuration
    public var soundId: String
    public var volume: Double // 0.0 - 1.0
    public var gradualVolume: Bool
    public var volumeRampDuration: TimeInterval
    public var gradualSoundIntensity: Bool
    public var voiceAnnouncementEnabled: Bool
    
    // Snooze & Backup
    public var snooze: SnoozeConfig
    public var backupAlarmEnabled: Bool
    public var backupAlarmDelaySeconds: TimeInterval
    public var backupSoundId: String
    
    // Hardcore challenges
    public var challenges: [ChallengeConfig]
    public var wakeUpVerification: WakeUpVerificationConfig
    
    // State controls
    public var skipNextOccurrence: Bool
    public var preset: AlarmPreset
    public var createdDate: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "Wake Up",
        details: String = "",
        hour: Int = 7,
        minute: Int = 0,
        isEnabled: Bool = true,
        repeatDays: Set<Weekday> = Weekday.weekdaysOnly,
        specificDate: Date? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        soundId: String = "emergency_siren",
        volume: Double = 0.9,
        gradualVolume: Bool = true,
        volumeRampDuration: TimeInterval = 20.0,
        gradualSoundIntensity: Bool = true,
        voiceAnnouncementEnabled: Bool = true,
        snooze: SnoozeConfig = SnoozeConfig(),
        backupAlarmEnabled: Bool = true,
        backupAlarmDelaySeconds: TimeInterval = 60.0,
        backupSoundId: String = "nuclear_klaxon",
        challenges: [ChallengeConfig] = AlarmPreset.hardcore.defaultChallenges,
        wakeUpVerification: WakeUpVerificationConfig = WakeUpVerificationConfig(isEnabled: true, delayMinutes: 5),
        skipNextOccurrence: Bool = false,
        preset: AlarmPreset = .hardcore,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.specificDate = specificDate
        self.startDate = startDate
        self.endDate = endDate
        self.soundId = soundId
        self.volume = volume
        self.gradualVolume = gradualVolume
        self.volumeRampDuration = volumeRampDuration
        self.gradualSoundIntensity = gradualSoundIntensity
        self.voiceAnnouncementEnabled = voiceAnnouncementEnabled
        self.snooze = snooze
        self.backupAlarmEnabled = backupAlarmEnabled
        self.backupAlarmDelaySeconds = backupAlarmDelaySeconds
        self.backupSoundId = backupSoundId
        self.challenges = challenges
        self.wakeUpVerification = wakeUpVerification
        self.skipNextOccurrence = skipNextOccurrence
        self.preset = preset
        self.createdDate = createdDate
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return String(format: "%02d:%02d", hour, minute)
    }
    
    public var formattedTime24Hour: String {
        return String(format: "%02d:%02d", hour, minute)
    }
    
    public var repeatSummary: String {
        if let specificDate = specificDate {
            let df = DateFormatter()
            df.dateStyle = .medium
            return "Once on \(df.string(from: specificDate))"
        }
        if repeatDays.isEmpty {
            return "Never (One-time)"
        }
        if repeatDays == Weekday.all {
            return "Every day"
        }
        if repeatDays == Weekday.weekdaysOnly {
            return "Weekdays"
        }
        if repeatDays == Weekday.weekendsOnly {
            return "Weekends"
        }
        let sorted = repeatDays.sorted()
        return sorted.map(\.shortName).joined(separator: ", ")
    }
    
    public static func makePresetAlarm(preset: AlarmPreset, hour: Int = 7, minute: Int = 0) -> Alarm {
        let alarm = Alarm(
            title: "\(preset.rawValue) Alarm",
            hour: hour,
            minute: minute,
            soundId: preset.defaultSoundId,
            volume: preset.defaultVolume,
            gradualVolume: preset.defaultRampDuration > 0,
            volumeRampDuration: preset.defaultRampDuration,
            snooze: SnoozeConfig(
                isEnabled: preset.defaultSnoozeAllowed,
                durationMinutes: 5,
                maxCount: preset.defaultMaxSnoozes,
                remainingCount: preset.defaultMaxSnoozes
            ),
            challenges: preset.defaultChallenges,
            wakeUpVerification: WakeUpVerificationConfig(
                isEnabled: preset.defaultVerificationEnabled,
                delayMinutes: preset.defaultVerificationDelayMinutes,
                stagesCount: preset.defaultVerificationStages
            ),
            preset: preset
        )
        return alarm
    }
}

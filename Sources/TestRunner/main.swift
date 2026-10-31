import Foundation
import HardcoreAlarmCore

var passedCount = 0
var failedCount = 0

@MainActor
func assertTest(_ condition: Bool, _ name: String, file: String = #file, line: Int = #line) {
    if condition {
        print("  \u{001B}[32m✓\u{001B}[0m \(name)")
        passedCount += 1
    } else {
        print("  \u{001B}[31m✗\u{001B}[0m \(name) (Failed at line \(line))")
        failedCount += 1
    }
}

print("\n=======================================================")
print("  🚨 HARDCORE ALARM SYSTEM — AUTOMATED TEST SUITE")
print("=======================================================\n")

// MARK: - 1. Math Challenge Tests
print("▶️ [1/5] Testing MathChallengeEngine...")
do {
    for diff in ChallengeDifficulty.allCases {
        let problem = MathChallengeEngine.generateProblem(difficulty: diff)
        assertTest(!problem.expression.isEmpty, "Math generation for \(diff.rawValue)")
        assertTest(problem.solution > -100000 && problem.solution < 100000, "Math solution bounded for \(diff.rawValue)")
    }
    
    let config = ChallengeConfig(type: .math, difficulty: .easy, questionCount: 2, mistakePenaltyQuestions: 1)
    let engine = MathChallengeEngine(config: config)
    assertTest(engine.questionsCompleted == 0, "Initial questions completed is 0")
    assertTest(!engine.isCompleted, "Initially not completed")
    
    // Correct answer 1
    let p1 = engine.currentProblem!
    let s1 = engine.submitAnswer(p1.solution)
    assertTest(s1, "Submit correct answer 1")
    assertTest(engine.questionsCompleted == 1, "Completed count is 1")
    
    // Correct answer 2
    let p2 = engine.currentProblem!
    let s2 = engine.submitAnswer(p2.solution)
    assertTest(s2, "Submit correct answer 2")
    assertTest(engine.questionsCompleted == 2, "Completed count is 2")
    assertTest(engine.isCompleted, "Challenge completed")
    
    // Penalty test
    let penaltyConfig = ChallengeConfig(type: .math, difficulty: .medium, questionCount: 3, mistakePenaltyQuestions: 2)
    let penaltyEngine = MathChallengeEngine(config: penaltyConfig)
    let wrong = (penaltyEngine.currentProblem?.solution ?? 0) + 999
    let wrongRes = penaltyEngine.submitAnswer(wrong)
    assertTest(!wrongRes, "Wrong answer rejected")
    assertTest(penaltyEngine.mistakesCount == 1, "Mistake recorded")
    assertTest(penaltyEngine.totalQuestionsRequired == 5, "Penalty questions added (3 -> 5)")
}

// MARK: - 2. Memory Challenge Tests
print("\n▶️ [2/5] Testing MemoryChallengeEngine...")
do {
    let easyConfig = ChallengeConfig(type: .memory, difficulty: .easy, gridSize: 3)
    let easyEngine = MemoryChallengeEngine(config: easyConfig)
    assertTest(easyEngine.sequenceLength == 4, "Easy memory length is 4")
    assertTest(easyEngine.sequence.count == 4, "Easy sequence generated 4 items")
    
    let insaneConfig = ChallengeConfig(type: .memory, difficulty: .insane, gridSize: 4)
    let insaneEngine = MemoryChallengeEngine(config: insaneConfig)
    assertTest(insaneEngine.sequenceLength == 10, "Insane memory length is 10")
    
    let maxTile = 4 * 4
    let allValid = insaneEngine.sequence.allSatisfy { $0 >= 0 && $0 < maxTile }
    assertTest(allValid, "All sequence tiles within 4x4 grid bounds")
}

// MARK: - 3. Typing Challenge Tests
print("\n▶️ [3/5] Testing TypingChallengeEngine...")
do {
    let config = ChallengeConfig(type: .typing, difficulty: .easy, accuracyRequired: 0.95)
    let engine = TypingChallengeEngine(config: config)
    assertTest(!engine.targetText.isEmpty, "Target text loaded")
    
    engine.currentInput = engine.targetText
    assertTest(engine.accuracy == 1.0, "100% accuracy on perfect typing")
    assertTest(engine.isCompleted, "Typing challenge marked completed")
    
    let strictConfig = ChallengeConfig(type: .typing, difficulty: .easy, accuracyRequired: 1.0)
    let strictEngine = TypingChallengeEngine(config: strictConfig)
    strictEngine.currentInput = "X" + String(strictEngine.targetText.dropFirst())
    assertTest(!strictEngine.isCompleted, "Typo prevents completion")
    assertTest(strictEngine.mistakeCount > 0, "Mistake count detected")
}

// MARK: - 4. Scheduler Tests
print("\n▶️ [4/5] Testing AlarmScheduler...")
do {
    let scheduler = AlarmScheduler.shared
    let now = Date()
    let cal = Calendar.current
    
    let target = cal.date(byAdding: .hour, value: 2, to: now)!
    let h = cal.component(.hour, from: target)
    let m = cal.component(.minute, from: target)
    
    let alarm = Alarm(hour: h, minute: m, isEnabled: true, repeatDays: [])
    let nextFire = scheduler.calculateNextFireDate(for: alarm, relativeTo: now)
    assertTest(nextFire != nil, "Calculated next fire date for one-time alarm")
    assertTest(nextFire! > now, "Fire date is in the future")
    
    let disabled = Alarm(hour: 7, minute: 0, isEnabled: false)
    assertTest(scheduler.calculateNextFireDate(for: disabled) == nil, "Disabled alarm returns nil")
    
    let normalRepeat = Alarm(hour: 7, minute: 0, isEnabled: true, repeatDays: Weekday.all, skipNextOccurrence: false)
    let skipRepeat = Alarm(hour: 7, minute: 0, isEnabled: true, repeatDays: Weekday.all, skipNextOccurrence: true)
    
    let f1 = scheduler.calculateNextFireDate(for: normalRepeat, relativeTo: now)!
    let f2 = scheduler.calculateNextFireDate(for: skipRepeat, relativeTo: now)!
    assertTest(f2 > f1, "Skipping next occurrence advances schedule into future")
}

// MARK: - 5. Anti-Sleep Verification Tests
print("\n▶️ [5/5] Testing WakeUpVerificationManager...")
do {
    let manager = WakeUpVerificationManager.shared
    manager.reset()
    assertTest(manager.status == .idle, "Initial manager state is idle")
    
    let alarm = Alarm(
        title: "Test Alarm",
        hour: 6,
        minute: 30,
        wakeUpVerification: WakeUpVerificationConfig(isEnabled: true, delayMinutes: 5, stagesCount: 2)
    )
    
    manager.startVerification(for: alarm)
    if case .pending(let title, let secondsRemaining, let stage, let total) = manager.status {
        assertTest(title == "Test Alarm", "Verification title matches")
        assertTest(stage == 1, "Verification stage is 1")
        assertTest(total == 2, "Total stages is 2")
        assertTest(secondsRemaining == 300, "5 minute countdown initialized (300s)")
    } else {
        assertTest(false, "Verification state should be pending")
    }
    
    manager.reset()
    assertTest(manager.status == .idle, "Manager reset back to idle")
}

print("\n=======================================================")
if failedCount == 0 {
    print("  🎉 ALL TESTS PASSED! (\(passedCount)/\(passedCount) tests)")
} else {
    print("  ❌ \(failedCount) TESTS FAILED! (\(passedCount) passed, \(failedCount) failed)")
}
print("=======================================================\n")

exit(failedCount == 0 ? 0 : 1)

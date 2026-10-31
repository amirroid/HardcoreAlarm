import SwiftUI
import Charts
import HardcoreAlarmCore

public struct StatisticsView: View {
    @UIState private var history: [AlarmHistoryRecord] = []
    
    public init() {}
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ANALYTICS & HISTORY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentAmber)
                        Text("Wake-Up Performance & Streaks")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                
                // Top Metric Cards Grid
                let total = history.count
                let successCount = history.filter(\.wasSuccessful).count
                let successRate = total > 0 ? Int((Double(successCount) / Double(total)) * 100) : 100
                let avgSolve = total > 0 ? Int(history.map(\.solveDurationSeconds).reduce(0, +) / Double(total)) : 0
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    StatCard(title: "TOTAL ALARMS", value: "\(total)", subtitle: "Recorded sessions", icon: "bell.fill", color: Theme.accentAmber)
                    StatCard(title: "SUCCESS RATE", value: "\(successRate)%", subtitle: "Solved challenges", icon: "checkmark.seal.fill", color: Theme.accentGreen)
                    StatCard(title: "CURRENT STREAK", value: "\(calculateStreak()) DAYS", subtitle: "Consecutive wakeups", icon: "flame.fill", color: Theme.accentRed)
                    StatCard(title: "AVG SOLVE TIME", value: "\(avgSolve)s", subtitle: "Time to silence", icon: "stopwatch.fill", color: Theme.accentBlue)
                }
                .padding(.horizontal, 28)
                
                // Weekly Activity Chart (SwiftUI Charts)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("DAILY SOLVE DURATION (PAST 7 SESSIONS)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                    }
                    
                    if history.isEmpty {
                        Text("No alarm sessions recorded yet.")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textMuted)
                            .frame(height: 160)
                    } else {
                        Chart {
                            ForEach(Array(history.prefix(7).enumerated()), id: \.element.id) { index, item in
                                BarMark(
                                    x: .value("Session", formatSessionLabel(item.firedTime)),
                                    y: .value("Seconds", item.solveDurationSeconds)
                                )
                                .foregroundStyle(LinearGradient(
                                    colors: [Theme.accentAmber, Theme.accentAmber.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .cornerRadius(6)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 180)
                        .padding(.top, 8)
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 28)
                
                // Challenge Types Performance Breakdown
                VStack(alignment: .leading, spacing: 14) {
                    Text("CHALLENGE PERFORMANCE BREAKDOWN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                    
                    HStack(spacing: 16) {
                        ChallengePerformanceBar(title: "Mathematics", icon: "function", accuracy: 94, color: Theme.accentAmber)
                        ChallengePerformanceBar(title: "Memory Grid", icon: "brain.head.profile", accuracy: 88, color: Theme.accentBlue)
                        ChallengePerformanceBar(title: "Typing Test", icon: "keyboard", accuracy: 98, color: Theme.accentViolet)
                        ChallengePerformanceBar(title: "Pattern Match", icon: "square.grid.3x3.fill", accuracy: 91, color: Theme.accentGreen)
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 28)
                
                // Recent Wake-Up History Log
                VStack(alignment: .leading, spacing: 14) {
                    Text("RECENT ALARM SESSIONS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                    
                    if history.isEmpty {
                        Text("No alarm history yet.")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textMuted)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(history.prefix(10)) { record in
                                HistoryRowView(record: record)
                            }
                        }
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .background(Theme.bgDeep.ignoresSafeArea())
        .onAppear {
            history = PersistenceService.shared.loadHistory()
        }
    }
    
    private func calculateStreak() -> Int {
        // Calculate consecutive successful days from history
        var streak = 0
        let cal = Calendar.current
        var lastDate: Date? = nil
        
        for record in history where record.wasSuccessful {
            if let last = lastDate {
                let diff = cal.dateComponents([.day], from: record.firedTime, to: last).day ?? 0
                if diff == 1 {
                    streak += 1
                } else if diff > 1 {
                    break
                }
            } else {
                streak = 1
            }
            lastDate = record.firedTime
        }
        return max(1, streak)
    }
    
    private func formatSessionLabel(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "E d"
        return df.string(from: date)
    }
}

// MARK: - Subcomponents
private struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(Theme.textDim)
        }
        .padding(16)
        .background(Theme.bgDeep)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderSubtle, lineWidth: 1))
    }
}

private struct ChallengePerformanceBar: View {
    let title: String
    let icon: String
    let accuracy: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(color)
            
            Text("\(accuracy)%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            ProgressView(value: Double(accuracy), total: 100)
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.bgDeep)
        .cornerRadius(10)
    }
}

private struct HistoryRowView: View {
    let record: AlarmHistoryRecord
    
    var body: some View {
        HStack {
            Image(systemName: record.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(record.wasSuccessful ? Theme.accentGreen : Theme.accentRed)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.alarmTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(formatTimestamp(record.firedTime))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Text("\(Int(record.solveDurationSeconds))s solve")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                
                if record.mistakeCount > 0 {
                    Text("\(record.mistakeCount) err")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.accentRed)
                }
                
                DifficultyBadge(difficulty: record.difficulty)
            }
        }
        .padding(12)
        .background(Theme.bgDeep)
        .cornerRadius(8)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: date)
    }
}

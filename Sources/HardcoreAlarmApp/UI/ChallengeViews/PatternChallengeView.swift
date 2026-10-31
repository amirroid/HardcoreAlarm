import SwiftUI
import HardcoreAlarmCore

public struct PatternChallengeView: View {
    @StateObject private var engine: PatternChallengeEngine
    public let onCompleted: () -> Void
    public let onMistake: () -> Void
    
    public init(config: ChallengeConfig, onCompleted: @escaping () -> Void, onMistake: @escaping () -> Void) {
        _engine = StateObject(wrappedValue: PatternChallengeEngine(config: config))
        self.onCompleted = onCompleted
        self.onMistake = onMistake
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PATTERN RECOGNITION")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentAmber)
                    Text(headerStatusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Text("ROUND \(engine.patternsCompleted + 1) OF \(engine.patternsRequired)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentAmber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Theme.bgDeep)
                            .overlay(Capsule().stroke(Theme.borderMedium, lineWidth: 1))
                    )
            }
            .padding(.horizontal, 24)
            
            // Grid
            let size = engine.gridSize
            let tileSize: CGFloat = size == 4 ? 65 : (size == 3 ? 85 : 55)
            
            VStack(spacing: 10) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(0..<size, id: \.self) { col in
                            let index = row * size + col
                            let isPatternCell = engine.activePattern.contains(index)
                            let isSelected = engine.selectedCells.contains(index)
                            
                            PatternCell(
                                isHighlighted: shouldHighlight(index: index, isPatternCell: isPatternCell, isSelected: isSelected),
                                isClickable: isRecalling,
                                tileSize: tileSize
                            ) {
                                engine.toggleCell(index)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
            
            // Footer Control
            if isRecalling {
                GlowingButton(title: "CONFIRM SELECTION", icon: "checkmark.circle.fill", style: .primary) {
                    let success = engine.submitSelection()
                    if !success {
                        onMistake()
                    } else if engine.state == .completed {
                        onCompleted()
                    }
                }
            } else if case .previewing(let sec) = engine.state {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.accentAmber)
                    Text("Memorize pattern... \(String(format: "%.1f", sec))s")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentAmber)
                }
            } else if case .mistakePenalty = engine.state {
                Text("INCORRECT PATTERN! RETRYING...")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentRed)
            }
        }
        .frame(maxWidth: 480)
        .onAppear {
            engine.startChallenge()
        }
        .onDisappear {
            engine.stop()
        }
    }
    
    private var isRecalling: Bool {
        if case .recalling = engine.state { return true }
        return false
    }
    
    private func shouldHighlight(index: Int, isPatternCell: Bool, isSelected: Bool) -> Bool {
        switch engine.state {
        case .previewing:
            return isPatternCell
        case .recalling:
            return isSelected
        case .mistakePenalty:
            return isPatternCell
        case .completed:
            return isPatternCell
        }
    }
    
    private var headerStatusText: String {
        switch engine.state {
        case .previewing: return "Memorize the active cells"
        case .recalling: return "Select the highlighted cells"
        case .mistakePenalty: return "Pattern mismatch!"
        case .completed: return "Pattern solved!"
        }
    }
}

private struct PatternCell: View {
    let isHighlighted: Bool
    let isClickable: Bool
    let tileSize: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            if isClickable {
                NSSound.beep()
                onTap()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHighlighted ? Theme.accentAmber : Theme.bgDeep)
                    .shadow(color: isHighlighted ? Theme.accentAmber.opacity(0.6) : Color.clear, radius: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHighlighted ? Color.white : Theme.borderMedium, lineWidth: 1.5)
                    )
            }
            .frame(width: tileSize, height: tileSize)
            .scaleEffect(isHighlighted ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        }
        .buttonStyle(.plain)
        .disabled(!isClickable)
    }
}

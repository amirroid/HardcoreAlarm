import SwiftUI
import HardcoreAlarmCore

public struct MemoryChallengeView: View {
    @StateObject private var engine: MemoryChallengeEngine
    public let onCompleted: () -> Void
    public let onMistake: () -> Void
    
    public init(config: ChallengeConfig, onCompleted: @escaping () -> Void, onMistake: @escaping () -> Void) {
        _engine = StateObject(wrappedValue: MemoryChallengeEngine(config: config))
        self.onCompleted = onCompleted
        self.onMistake = onMistake
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MEMORY SEQUENCE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentBlue)
                    Text(statusText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Text("LENGTH: \(engine.sequenceLength)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Theme.bgDeep)
                            .overlay(Capsule().stroke(Theme.borderMedium, lineWidth: 1))
                    )
            }
            .padding(.horizontal, 24)
            
            // Grid Display
            let size = engine.gridSize
            let tileSize: CGFloat = size == 3 ? 90 : 70
            
            VStack(spacing: 12) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<size, id: \.self) { col in
                            let index = row * size + col
                            MemoryTile(
                                index: index,
                                isHighlighted: engine.activeHighlightedTile == index,
                                isClickable: isInputAllowed,
                                tileSize: tileSize
                            ) {
                                let success = engine.inputTile(index)
                                if !success {
                                    onMistake()
                                } else if engine.state == .completed {
                                    onCompleted()
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
            .glassCard(cornerRadius: 20)
            
            // Progress Bar / Subtext
            if case .waitingForInput(let step) = engine.state {
                VStack(spacing: 8) {
                    ProgressView(value: Double(step), total: Double(engine.sequenceLength))
                        .tint(Theme.accentBlue)
                        .frame(width: 200)
                    Text("Step \(step) of \(engine.sequenceLength)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
            } else if case .showingSequence = engine.state {
                Text("Memorizing sequence...")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accentAmber)
            } else if case .errorPenalty = engine.state {
                Text("WRONG TILE! SEQUENCE RESETTING...")
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
    
    private var isInputAllowed: Bool {
        if case .waitingForInput = engine.state {
            return true
        }
        return false
    }
    
    private var statusText: String {
        switch engine.state {
        case .ready: return "Get ready..."
        case .showingSequence: return "Watch sequence carefully"
        case .waitingForInput: return "Reproduce the sequence"
        case .errorPenalty: return "Sequence failed!"
        case .completed: return "Memory challenge complete!"
        }
    }
}

private struct MemoryTile: View {
    let index: Int
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
                RoundedRectangle(cornerRadius: 14)
                    .fill(isHighlighted ? Theme.accentBlue : Theme.bgDeep)
                    .shadow(color: isHighlighted ? Theme.accentBlue.opacity(0.8) : Color.clear, radius: 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isHighlighted ? Color.white : Theme.borderMedium, lineWidth: 1.5)
                    )
                
                Circle()
                    .fill(isHighlighted ? Color.white : Theme.textDim)
                    .frame(width: 10, height: 10)
            }
            .frame(width: tileSize, height: tileSize)
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        }
        .buttonStyle(.plain)
        .disabled(!isClickable)
    }
}

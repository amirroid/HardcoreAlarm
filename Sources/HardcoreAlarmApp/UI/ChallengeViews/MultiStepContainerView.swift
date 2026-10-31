import SwiftUI
import HardcoreAlarmCore

public struct MultiStepContainerView: View {
    @StateObject private var engine: MultiStepChallengeEngine
    public let onAllCompleted: (TimeInterval, Int, [ChallengeType]) -> Void
    public let onMistake: () -> Void
    
    public init(challenges: [ChallengeConfig], onAllCompleted: @escaping (TimeInterval, Int, [ChallengeType]) -> Void, onMistake: @escaping () -> Void) {
        _engine = StateObject(wrappedValue: MultiStepChallengeEngine(challenges: challenges))
        self.onAllCompleted = onAllCompleted
        self.onMistake = onMistake
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Pipeline Stepper
            HStack(spacing: 8) {
                ForEach(0..<engine.totalSteps, id: \.self) { idx in
                    let stepChallenge = engine.challenges[idx]
                    HStack(spacing: 6) {
                        Image(systemName: stepChallenge.type.iconName)
                            .font(.system(size: 11, weight: .bold))
                        Text("STEP \(idx + 1)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(stepColor(for: idx))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(stepBg(for: idx))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(stepBorder(for: idx), lineWidth: 1))
                    )
                    
                    if idx < engine.totalSteps - 1 {
                        Rectangle()
                            .fill(idx < engine.currentStepIndex ? Theme.accentGreen : Theme.borderSubtle)
                            .frame(width: 14, height: 2)
                    }
                }
            }
            .padding(.top, 10)
            
            // Active Step Content
            let current = engine.currentChallenge
            Group {
                switch current.type {
                case .math:
                    MathChallengeView(config: current, onCompleted: {
                        handleStepCompletion()
                    }, onMistake: {
                        engine.recordMistake()
                        onMistake()
                    })
                case .memory:
                    MemoryChallengeView(config: current, onCompleted: {
                        handleStepCompletion()
                    }, onMistake: {
                        engine.recordMistake()
                        onMistake()
                    })
                case .typing:
                    TypingChallengeView(config: current, onCompleted: {
                        handleStepCompletion()
                    }, onMistake: {
                        engine.recordMistake()
                        onMistake()
                    })
                case .pattern:
                    PatternChallengeView(config: current, onCompleted: {
                        handleStepCompletion()
                    }, onMistake: {
                        engine.recordMistake()
                        onMistake()
                    })
                case .multiStep:
                    // Fallback to math
                    MathChallengeView(config: ChallengeConfig.defaultMath, onCompleted: {
                        handleStepCompletion()
                    }, onMistake: {
                        engine.recordMistake()
                        onMistake()
                    })
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            .id(engine.currentStepIndex)
        }
    }
    
    private func handleStepCompletion() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            engine.completeCurrentStep()
            if engine.isAllCompleted {
                onAllCompleted(engine.totalElapsedTime, engine.totalMistakes, engine.completedTypes)
            }
        }
    }
    
    private func stepColor(for idx: Int) -> Color {
        if idx < engine.currentStepIndex {
            return Theme.accentGreen
        } else if idx == engine.currentStepIndex {
            return Theme.accentAmber
        } else {
            return Theme.textDim
        }
    }
    
    private func stepBg(for idx: Int) -> Color {
        if idx < engine.currentStepIndex {
            return Theme.accentGreen.opacity(0.12)
        } else if idx == engine.currentStepIndex {
            return Theme.accentAmber.opacity(0.15)
        } else {
            return Theme.bgDeep
        }
    }
    
    private func stepBorder(for idx: Int) -> Color {
        if idx < engine.currentStepIndex {
            return Theme.accentGreen.opacity(0.4)
        } else if idx == engine.currentStepIndex {
            return Theme.accentAmber.opacity(0.5)
        } else {
            return Theme.borderSubtle
        }
    }
}

import SwiftUI
import HardcoreAlarmCore

public struct MathChallengeView: View {
    @StateObject private var engine: MathChallengeEngine
    @UIState private var inputString: String = ""
    @UIState private var shakeOffset: CGFloat = 0
    @UIState private var showPenaltyNotice = false
    
    public let onCompleted: () -> Void
    public let onMistake: () -> Void
    
    public init(config: ChallengeConfig, onCompleted: @escaping () -> Void, onMistake: @escaping () -> Void) {
        _engine = StateObject(wrappedValue: MathChallengeEngine(config: config))
        self.onCompleted = onCompleted
        self.onMistake = onMistake
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header: Progress & Mistakes
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MATH CHALLENGE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentAmber)
                    Text("Solve to silence alarm")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Text("QUESTION \(engine.questionsCompleted + 1) OF \(engine.totalQuestionsRequired)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Theme.bgDeep)
                            .overlay(Capsule().stroke(Theme.borderMedium, lineWidth: 1))
                    )
            }
            .padding(.horizontal, 24)
            
            // Penalty Notice
            if engine.mistakesCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.accentRed)
                    Text("WRONG ANSWER! +\(engine.lastMistakePenaltyApplied) PENALTY QUESTIONS ADDED")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentRed)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.accentRed.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accentRed.opacity(0.3), lineWidth: 1))
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Formula Card
            if let problem = engine.currentProblem {
                VStack(spacing: 12) {
                    Text(problem.expression)
                        .font(.system(size: 44, weight: .black, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    
                    // Answer Input Display
                    HStack(spacing: 4) {
                        Text("=")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textDim)
                        
                        Text(inputString.isEmpty ? " " : inputString)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentAmber)
                            .frame(minWidth: 120, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.bgDeep)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.accentAmber.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 24)
                .offset(x: shakeOffset)
            }
            
            // Tactile Keypad
            TactileKeypad(
                onNumber: { num in
                    if inputString.count < 6 {
                        inputString.append("\(num)")
                    }
                },
                onDelete: {
                    if !inputString.isEmpty {
                        inputString.removeLast()
                    }
                },
                onSubmit: {
                    submit()
                }
            )
            .padding(.bottom, 16)
        }
        .frame(maxWidth: 480)
        // Hidden keyboard listener for Mac hardware keyboard
        .background(
            KeyboardListenerView { key in
                handleHardwareKey(key)
            }
        )
    }
    
    private func submit() {
        guard let answer = Int(inputString) else { return }
        inputString = ""
        let success = engine.submitAnswer(answer)
        
        if success {
            if engine.isCompleted {
                onCompleted()
            }
        } else {
            onMistake()
            triggerShake()
        }
    }
    
    private func triggerShake() {
        withAnimation(.default) {
            shakeOffset = -15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { self.shakeOffset = 15 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { self.shakeOffset = -8 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) { self.shakeOffset = 0 }
        }
    }
    
    private func handleHardwareKey(_ key: String) {
        if let num = Int(key) {
            if inputString.count < 6 { inputString.append("\(num)") }
        } else if key == "\u{7F}" || key == "\u{08}" { // Backspace
            if !inputString.isEmpty { inputString.removeLast() }
        } else if key == "\r" || key == "\n" { // Return / Enter
            submit()
        }
    }
}

// AppKit Invisible Hardware Key Handler
public struct KeyboardListenerView: NSViewRepresentable {
    public let onKeyPress: (String) -> Void
    
    public func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        view.onKeyPress = onKeyPress
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    public func updateNSView(_ nsView: KeyView, context: Context) {
        nsView.onKeyPress = onKeyPress
    }
    
    public class KeyView: NSView {
        var onKeyPress: ((String) -> Void)?
        
        public override var acceptsFirstResponder: Bool { true }
        
        public override func keyDown(with event: NSEvent) {
            if let chars = event.characters {
                onKeyPress?(chars)
            } else {
                super.keyDown(with: event)
            }
        }
    }
}

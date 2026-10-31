import SwiftUI
import HardcoreAlarmCore

public struct TypingChallengeView: View {
    @StateObject private var engine: TypingChallengeEngine
    @FocusState private var isFieldFocused: Bool
    
    public let onCompleted: () -> Void
    public let onMistake: () -> Void
    
    public init(config: ChallengeConfig, onCompleted: @escaping () -> Void, onMistake: @escaping () -> Void) {
        _engine = StateObject(wrappedValue: TypingChallengeEngine(config: config))
        self.onCompleted = onCompleted
        self.onMistake = onMistake
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HARDCORE TYPING CHALLENGE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accentViolet)
                    Text("Type the exact text below to dismiss")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    StatPill(title: "ACCURACY", value: "\(Int(engine.accuracy * 100))%", color: engine.accuracy >= engine.accuracyRequired ? Theme.accentGreen : Theme.accentRed)
                    StatPill(title: "WPM", value: "\(Int(engine.wordsPerMinute))", color: Theme.accentViolet)
                }
            }
            .padding(.horizontal, 24)
            
            // Text Visualizer Card
            VStack(alignment: .leading, spacing: 16) {
                // Character-by-character colored rendering
                HighlightedQuoteView(targetText: engine.targetText, currentInput: engine.currentInput)
                    .lineSpacing(6)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.bgDeep)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderSubtle, lineWidth: 1))
                
                // Actual interactive typing input
                TextField("Start typing here...", text: $engine.currentInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .padding(14)
                    .background(Theme.bgDeep.opacity(0.8))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(engine.accuracy >= engine.accuracyRequired ? Theme.accentViolet.opacity(0.5) : Theme.accentRed.opacity(0.5), lineWidth: 1.5)
                    )
                    .focused($isFieldFocused)
                    .disableAutocorrection(true)
                    .onChange(of: engine.isCompleted) { _, completed in
                        if completed {
                            onCompleted()
                        }
                    }
                    .onChange(of: engine.mistakeCount) { _, newErrors in
                        if newErrors > 0 {
                            onMistake()
                        }
                    }
            }
            .padding(20)
            .glassCard(cornerRadius: 20)
            .padding(.horizontal, 24)
            
            // Minimum Requirement Notice
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield")
                    .foregroundColor(Theme.accentGreen)
                Text("Required accuracy: \(Int(engine.accuracyRequired * 100))% • No typos allowed upon completion")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .frame(maxWidth: 560)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFieldFocused = true
            }
        }
    }
}

private struct HighlightedQuoteView: View {
    let targetText: String
    let currentInput: String
    
    var body: some View {
        let targetChars = Array(targetText)
        let inputChars = Array(currentInput)
        
        Text(buildAttributedString(targetChars: targetChars, inputChars: inputChars))
            .font(.system(size: 16, weight: .regular, design: .monospaced))
    }
    
    private func buildAttributedString(targetChars: [Character], inputChars: [Character]) -> AttributedString {
        var str = AttributedString()
        
        for i in 0..<targetChars.count {
            let targetChar = String(targetChars[i])
            var charAttr = AttributedString(targetChar)
            
            if i < inputChars.count {
                if inputChars[i] == targetChars[i] {
                    // Correct character
                    charAttr.foregroundColor = NSColor(Theme.accentGreen)
                    charAttr.inlinePresentationIntent = .stronglyEmphasized
                } else {
                    // Wrong character typed
                    charAttr.foregroundColor = NSColor(Theme.accentRed)
                    charAttr.backgroundColor = NSColor(Theme.accentRed.opacity(0.2))
                }
            } else if i == inputChars.count {
                // Cursor position
                charAttr.foregroundColor = NSColor.white
                charAttr.underlineStyle = .single
            } else {
                // Untyped character
                charAttr.foregroundColor = NSColor(Theme.textDim)
            }
            str.append(charAttr)
        }
        
        return str
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.bgDeep)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderSubtle, lineWidth: 1))
        )
    }
}

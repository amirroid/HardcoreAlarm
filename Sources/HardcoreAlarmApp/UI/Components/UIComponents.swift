import SwiftUI
import HardcoreAlarmCore

// MARK: - Difficulty Badge
public struct DifficultyBadge: View {
    public let difficulty: ChallengeDifficulty
    
    public init(difficulty: ChallengeDifficulty) {
        self.difficulty = difficulty
    }
    
    private var color: Color {
        switch difficulty {
        case .easy: return Theme.accentGreen
        case .medium: return Theme.accentBlue
        case .hard: return Theme.accentAmber
        case .insane: return Theme.accentRed
        }
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(difficulty.rawValue.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Preset Badge
public struct PresetBadge: View {
    public let preset: AlarmPreset
    
    public init(preset: AlarmPreset) {
        self.preset = preset
    }
    
    private var color: Color {
        switch preset {
        case .gentle: return Theme.accentGreen
        case .normal: return Theme.accentBlue
        case .hardcore: return Theme.accentAmber
        case .extreme: return Theme.accentRed
        case .impossible: return Theme.accentViolet
        case .custom: return Color.gray
        }
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: preset.iconName)
                .font(.system(size: 11, weight: .semibold))
            Text(preset.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Glowing Button
public struct GlowingButton: View {
    public enum Style {
        case primary
        case secondary
        case hardcore
        case danger
    }
    
    public let title: String
    public let icon: String?
    public let style: Style
    public let action: () -> Void
    
    @UIState private var isHovered = false
    
    public init(title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    private var bgFill: Color {
        switch style {
        case .primary: return isHovered ? Theme.accentAmber.opacity(0.9) : Theme.accentAmber
        case .secondary: return isHovered ? Theme.bgCardHover : Theme.bgCard
        case .hardcore: return isHovered ? Theme.accentRed.opacity(0.9) : Theme.accentRed
        case .danger: return isHovered ? Color.red.opacity(0.3) : Color.red.opacity(0.2)
        }
    }
    
    private var fgColor: Color {
        switch style {
        case .primary, .hardcore: return Color.black
        case .secondary: return Color.white
        case .danger: return Theme.accentRed
        }
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(fgColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(bgFill)
                    .shadow(color: (style == .primary ? Theme.accentAmber : (style == .hardcore ? Theme.accentRed : Color.clear)).opacity(isHovered ? 0.4 : 0.2), radius: isHovered ? 10 : 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style == .secondary ? Theme.borderMedium : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Digital Countdown View
public struct DigitalCountdownView: View {
    public let remainingSeconds: TimeInterval?
    
    public init(remainingSeconds: TimeInterval?) {
        self.remainingSeconds = remainingSeconds
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            if let seconds = remainingSeconds, seconds > 0 {
                let hours = Int(seconds) / 3600
                let mins = (Int(seconds) % 3600) / 60
                let secs = Int(seconds) % 60
                
                TimeUnitView(value: String(format: "%02d", hours), label: "HOURS")
                Text(":")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textDim)
                    .offset(y: -8)
                TimeUnitView(value: String(format: "%02d", mins), label: "MINUTES")
                Text(":")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textDim)
                    .offset(y: -8)
                TimeUnitView(value: String(format: "%02d", secs), label: "SECONDS", isSeconds: true)
            } else {
                Text("NO ALARM SCHEDULED")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                    .padding(.vertical, 12)
            }
        }
    }
}

private struct TimeUnitView: View {
    let value: String
    let label: String
    var isSeconds: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 42, weight: .bold, design: .monospaced))
                .foregroundColor(isSeconds ? Theme.accentAmber : Theme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.bgDeep.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSeconds ? Theme.accentAmber.opacity(0.3) : Theme.borderSubtle, lineWidth: 1)
                        )
                )
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
        }
    }
}

// MARK: - Tactile Keypad
public struct TactileKeypad: View {
    public let onNumber: (Int) -> Void
    public let onDelete: () -> Void
    public let onSubmit: () -> Void
    
    public init(onNumber: @escaping (Int) -> Void, onDelete: @escaping () -> Void, onSubmit: @escaping () -> Void) {
        self.onNumber = onNumber
        self.onDelete = onDelete
        self.onSubmit = onSubmit
    }
    
    private let rows: [[KeyType]] = [
        [.num(1), .num(2), .num(3)],
        [.num(4), .num(5), .num(6)],
        [.num(7), .num(8), .num(9)],
        [.delete, .num(0), .submit]
    ]
    
    public enum KeyType {
        case num(Int)
        case delete
        case submit
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<rows.count, id: \.self) { rowIdx in
                HStack(spacing: 10) {
                    ForEach(0..<rows[rowIdx].count, id: \.self) { colIdx in
                        let key = rows[rowIdx][colIdx]
                        KeyButton(key: key) {
                            switch key {
                            case .num(let n): onNumber(n)
                            case .delete: onDelete()
                            case .submit: onSubmit()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct KeyButton: View {
    let key: TactileKeypad.KeyType
    let action: () -> Void
    @UIState private var isPressed = false
    
    var body: some View {
        Button(action: {
            NSSound.beep() // Tactile click feedback
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(keyBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(keyBorder, lineWidth: 1)
                    )
                
                switch key {
                case .num(let n):
                    Text("\(n)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                case .delete:
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.accentRed)
                case .submit:
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.accentGreen)
                }
            }
            .frame(width: 80, height: 60)
        }
        .buttonStyle(.plain)
    }
    
    private var keyBackground: Color {
        switch key {
        case .submit: return Theme.accentGreen.opacity(0.2)
        case .delete: return Theme.accentRed.opacity(0.15)
        case .num: return Theme.bgCard
        }
    }
    
    private var keyBorder: Color {
        switch key {
        case .submit: return Theme.accentGreen.opacity(0.4)
        case .delete: return Theme.accentRed.opacity(0.3)
        case .num: return Theme.borderMedium
        }
    }
}

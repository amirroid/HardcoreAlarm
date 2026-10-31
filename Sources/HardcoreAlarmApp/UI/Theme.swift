import SwiftUI

public struct Theme {
    // Charcoal Palette
    public static let bgDeep = Color(red: 0.04, green: 0.045, blue: 0.06)
    public static let bgSecondary = Color(red: 0.07, green: 0.08, blue: 0.11)
    public static let bgCard = Color(red: 0.10, green: 0.11, blue: 0.15)
    public static let bgCardHover = Color(red: 0.14, green: 0.15, blue: 0.20)
    
    // Glass & Borders
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderMedium = Color.white.opacity(0.15)
    public static let borderActive = Color.white.opacity(0.3)
    
    // Text Hierarchy
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.7)
    public static let textMuted = Color.white.opacity(0.4)
    public static let textDim = Color.white.opacity(0.2)
    
    // Accents & Signals
    public static let accentAmber = Color(red: 1.0, green: 0.65, blue: 0.15)
    public static let accentRed = Color(red: 1.0, green: 0.25, blue: 0.25)
    public static let accentGreen = Color(red: 0.2, green: 0.85, blue: 0.5)
    public static let accentBlue = Color(red: 0.2, green: 0.65, blue: 1.0)
    public static let accentViolet = Color(red: 0.75, green: 0.35, blue: 1.0)
    
    // Fonts
    public static func clockFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
    
    public static func titleFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    public static func subtitleFont(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

// Visual Card Modifier
public struct GlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 16
    public var strokeColor: Color = Theme.borderSubtle
    public var isHighlighted: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.bgCard)
                    .shadow(color: isHighlighted ? Theme.accentAmber.opacity(0.15) : Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHighlighted ? Theme.accentAmber.opacity(0.4) : strokeColor, lineWidth: 1)
            )
    }
}

public extension View {
    func glassCard(cornerRadius: CGFloat = 16, strokeColor: Color = Theme.borderSubtle, isHighlighted: Bool = false) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, strokeColor: strokeColor, isHighlighted: isHighlighted))
    }
}

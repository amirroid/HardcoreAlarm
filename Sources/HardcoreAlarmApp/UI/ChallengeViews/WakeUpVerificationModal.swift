import SwiftUI
import HardcoreAlarmCore

public struct WakeUpVerificationModal: View {
    @ObservedObject var verificationManager = WakeUpVerificationManager.shared
    @UIState private var holdProgress: Double = 0.0
    @UIState private var isHolding: Bool = false
    @UIState private var holdTimer: Timer?
    
    public var body: some View {
        if case .promptActive(let title, let secondsRemaining, let stage) = verificationManager.status {
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Critical Alert Icon
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.accentAmber)
                        .shadow(color: Theme.accentAmber.opacity(0.6), radius: 15)
                    
                    VStack(spacing: 8) {
                        Text("WAKE-UP VERIFICATION: STAGE \(stage)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accentAmber)
                        
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Confirm you are awake! If you fail to respond before the timer expires, the hardcore alarm will re-engage at maximum volume.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Countdown Ring
                    ZStack {
                        Circle()
                            .stroke(Theme.borderMedium, lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: CGFloat(secondsRemaining) / 60.0)
                            .stroke(secondsRemaining < 15 ? Theme.accentRed : Theme.accentAmber, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1.0), value: secondsRemaining)
                        
                        VStack(spacing: 2) {
                            Text("\(secondsRemaining)")
                                .font(.system(size: 32, weight: .black, design: .monospaced))
                                .foregroundColor(Theme.textPrimary)
                            Text("SECONDS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .frame(width: 100, height: 100)
                    
                    // Hold to confirm button
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.bgDeep)
                                .frame(height: 54)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.accentGreen.opacity(0.4))
                                .frame(width: CGFloat(holdProgress) * 320, height: 54)
                            
                            HStack {
                                Spacer()
                                Text(isHolding ? "HOLDING... \(Int(holdProgress * 100))%" : "PRESS & HOLD TO CONFIRM AWAKE")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                        }
                        .frame(width: 320)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.accentGreen.opacity(0.6), lineWidth: 1.5)
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isHolding {
                                        startHolding()
                                    }
                                }
                                .onEnded { _ in
                                    stopHolding()
                                }
                        )
                        
                        Text("Hold for 2 seconds to prove alertness")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .padding(32)
                .glassCard(cornerRadius: 24, strokeColor: Theme.accentAmber.opacity(0.4), isHighlighted: true)
                .frame(maxWidth: 480)
            }
            .transition(.opacity)
        }
    }
    
    private func startHolding() {
        isHolding = true
        holdTimer?.invalidate()
        let timer = Timer(timeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                self.holdProgress += 0.025 // 2 seconds total (0.05 * 40 steps)
                if self.holdProgress >= 1.0 {
                    self.stopHolding()
                    NSSound.beep()
                    self.verificationManager.confirmAwake()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        holdTimer = timer
    }
    
    private func stopHolding() {
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0.0
        }
    }
}

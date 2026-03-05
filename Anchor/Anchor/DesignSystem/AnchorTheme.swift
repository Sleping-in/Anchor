//
//  AnchorTheme.swift
//  Anchor
//
//  Design system for Anchor UI Lawbook
//

import SwiftUI

enum AnchorTheme {
    enum Colors {
        // Adaptive colours — warm light / warm dark
        static let softParchment = Color("softParchment")
        static let warmStone     = Color("warmStone")
        static let warmSand      = Color("warmSand")
        static let quietInk      = Color("quietInk")
        static let quietInkSecondary = Color("quietInkSecondary")

        // Accent colours — shared across schemes
        static let sageLeaf        = Color(hex: "#8DA399")
        static let etherBlue       = Color(hex: "#38BDF8")
        static let pulsePink       = Color(hex: "#F472B6")
        static let thinkingViolet  = Color(hex: "#A78BFA")
        static let crisisRed       = Color(hex: "#EF4444")

        static func accent(for state: OrbState) -> Color {
            switch state {
            case .idle: return sageLeaf
            case .connecting: return warmSand
            case .listening: return etherBlue
            case .thinking: return thinkingViolet
            case .speaking: return pulsePink
            case .crisis: return crisisRed
            }
        }
    }

    enum Typography {
        static func heading(
            size: CGFloat,
            weight: Font.Weight = .semibold,
            relativeTo textStyle: Font.TextStyle = .title2
        ) -> Font {
            Font.custom("Playfair Display", size: size, relativeTo: textStyle).weight(weight)
        }

        static func body(
            size: CGFloat,
            weight: Font.Weight = .regular,
            relativeTo textStyle: Font.TextStyle = .body
        ) -> Font {
            Font.custom("Source Sans 3", size: size, relativeTo: textStyle).weight(weight)
        }

        static let title = heading(size: 30, weight: .semibold, relativeTo: .title2)
        static let headline = heading(size: 22, weight: .semibold, relativeTo: .headline)
        static let subheadline = body(size: 17, weight: .medium, relativeTo: .subheadline)
        static let bodyText = body(size: 16, weight: .regular, relativeTo: .body)
        static let caption = body(size: 13, weight: .regular, relativeTo: .caption)
        static let smallCaption = body(size: 12, weight: .regular, relativeTo: .caption2)
    }

    enum Motion {
        static let breathingDuration: Double = 7.5
        static let transitionDuration: Double = 0.75

        static let gentleSpring = Animation.spring(response: 1.6, dampingFraction: 0.9, blendDuration: 0.2)
        static let breathing = Animation.spring(response: 2.8, dampingFraction: 0.92, blendDuration: 0.2)
            .repeatForever(autoreverses: true)
    }

    enum Layout {
        static let cardRadius: CGFloat = 18
        static let controlRadius: CGFloat = 999
        static let cardBorderOpacity: Double = 0.08
        static let cardPadding: CGFloat = 16
    }
}

enum OrbState {
    case idle
    case connecting
    case listening
    case thinking
    case speaking
    case crisis
}

struct OrbView: View {
    let state: OrbState
    var size: CGFloat = 200
    var allowsCoreDrift: Bool = true
    var allowsBreathingScale: Bool = true
    var allowsAnimations: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false
    @State private var drift = false
    @State private var pulse = false
    @State private var thinkingRotation: Double = 0

    private var accent: Color { AnchorTheme.Colors.accent(for: state) }

    var body: some View {
        ZStack {
            // ── Outer glow ring ───────────────────────────────────
            Circle()
                .fill(outerGradient)
                .frame(width: size * 1.25, height: size * 1.25)
                .blur(radius: 28)
                .opacity(glowOpacity)
                .scaleEffect(outerScale)

            // ── Main body ─────────────────────────────────────────
            Circle()
                .fill(orbGradient)
                .frame(width: size, height: size)
                .blur(radius: 14)
                .opacity(bodyOpacity)
                .scaleEffect(bodyScale)

            // ── Inner core ────────────────────────────────────────
            Circle()
                .fill(orbCoreGradient)
                .frame(width: size * 0.5, height: size * 0.5)
                .blur(radius: 10)
                .opacity(drift ? 0.9 : 0.65)
                .offset(x: coreOffset.x, y: coreOffset.y)

            // ── Thinking spinner ring ─────────────────────────────
            if state == .thinking {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [accent.opacity(0.7), accent.opacity(0.05), accent.opacity(0.7)],
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: size * 0.86, height: size * 0.86)
                    .rotationEffect(.degrees(thinkingRotation))
            }
        }
        .frame(width: size * 1.25, height: size * 1.25)
        .accessibilityLabel(orbAccessibilityLabel)
        .animation(.easeInOut(duration: 0.7), value: state)
        .onAppear {
            if allowsAnimations {
                startAnimations()
            } else {
                breathe = false
                drift = false
                pulse = false
                thinkingRotation = 0
            }
        }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced || !allowsAnimations {
                breathe = false; drift = false; pulse = false; thinkingRotation = 0
            } else {
                startAnimations()
            }
        }
        .onChange(of: state) { _, newState in
            guard allowsAnimations else {
                pulse = false
                thinkingRotation = 0
                return
            }
            restartPulse()
            if newState == .thinking {
                startThinkingRotation()
            } else {
                thinkingRotation = 0
            }
        }
    }

    // MARK: - State-driven visuals

    private var glowOpacity: Double {
        switch state {
        case .idle:        return 0.12
        case .connecting:  return 0.2
        case .listening:   return 0.35
        case .thinking:    return 0.45
        case .speaking:    return 0.55
        case .crisis:      return 0.6
        }
    }

    private var bodyOpacity: Double {
        switch state {
        case .idle:        return 0.65
        case .connecting:  return 0.7
        case .listening:   return breathe ? 0.88 : 0.75
        case .thinking:    return pulse ? 0.85 : 0.68
        case .speaking:    return pulse ? 0.95 : 0.78
        case .crisis:      return 0.9
        }
    }

    private var bodyScale: CGFloat {
        guard allowsBreathingScale else { return 1.0 }
        switch state {
        case .idle:        return breathe ? 1.02 : 0.98
        case .connecting:  return pulse ? 1.01 : 0.99
        case .listening:   return breathe ? 1.04 : 0.96
        case .thinking:    return pulse ? 1.03 : 0.97
        case .speaking:    return pulse ? 1.09 : 0.95
        case .crisis:      return pulse ? 1.06 : 0.94
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        guard !reduceMotion else { return }
        if allowsBreathingScale {
            withAnimation(AnchorTheme.Motion.breathing) {
                breathe.toggle()
            }
        } else {
            breathe = false
        }
        if allowsCoreDrift {
            withAnimation(AnchorTheme.Motion.breathing.delay(0.5)) {
                drift.toggle()
            }
        } else {
            drift = false
        }
        restartPulse()
        if state == .thinking { startThinkingRotation() }
    }

    private func restartPulse() {
        guard !reduceMotion else { return }
        pulse = false
        let speed: Double = (state == .speaking) ? 1.0 : 2.2
        withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }

    private func startThinkingRotation() {
        guard !reduceMotion else { return }
        thinkingRotation = 0
        withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
            thinkingRotation = 360
        }
    }

    private var coreOffset: CGPoint {
        guard allowsCoreDrift else { return .zero }
        return CGPoint(x: drift ? -4 : 3, y: drift ? 3 : -4)
    }

    private var outerScale: CGFloat {
        guard allowsBreathingScale else { return 1.0 }
        return breathe ? 1.08 : 0.94
    }

    // MARK: - Gradients

    private var outerGradient: RadialGradient {
        RadialGradient(
            colors: [accent.opacity(0.3), accent.opacity(0.02)],
            center: .center,
            startRadius: 10,
            endRadius: size * 0.7
        )
    }

    private var orbGradient: RadialGradient {
        RadialGradient(
            colors: [accent.opacity(0.55), accent.opacity(0.15), AnchorTheme.Colors.warmSand.opacity(0.05)],
            center: .center,
            startRadius: 10,
            endRadius: size * 0.6
        )
    }

    private var orbCoreGradient: RadialGradient {
        RadialGradient(
            colors: [accent.opacity(0.5), accent.opacity(0.1)],
            center: .center,
            startRadius: 4,
            endRadius: size * 0.28
        )
    }

    private var orbAccessibilityLabel: String {
        switch state {
        case .idle: return "Anchor is idle"
        case .connecting: return "Anchor is connecting"
        case .listening: return "Anchor is listening"
        case .thinking: return "Anchor is thinking"
        case .speaking: return "Anchor is speaking"
        case .crisis: return "Crisis mode active"
        }
    }
}

struct AnchorCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AnchorTheme.Layout.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AnchorTheme.Layout.cardRadius)
                    .fill(AnchorTheme.Colors.warmStone)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AnchorTheme.Layout.cardRadius)
                    .stroke(AnchorTheme.Colors.warmSand.opacity(AnchorTheme.Layout.cardBorderOpacity), lineWidth: 1)
            )
    }
}

struct AnchorPillButtonStyle: ButtonStyle {
    var background: Color = AnchorTheme.Colors.sageLeaf
    var foreground: Color = AnchorTheme.Colors.softParchment

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(minHeight: 48)
            .background(
                Capsule()
                    .fill(background.opacity(configuration.isPressed ? 0.85 : 1.0))
            )
            .foregroundColor(foreground)
            .animation(AnchorTheme.Motion.gentleSpring, value: configuration.isPressed)
    }
}

extension View {
    func anchorCard() -> some View {
        modifier(AnchorCardModifier())
    }

    func anchorScreenBackground() -> some View {
        background(AnchorTheme.Colors.softParchment.ignoresSafeArea())
    }

    func anchorPrimaryText() -> some View {
        foregroundColor(AnchorTheme.Colors.quietInk)
    }

    func anchorSecondaryText() -> some View {
        foregroundColor(AnchorTheme.Colors.quietInkSecondary)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: min(max(Double(r) / 255, 0), 1),
            green: min(max(Double(g) / 255, 0), 1),
            blue: min(max(Double(b) / 255, 0), 1),
            opacity: min(max(Double(a) / 255, 0), 1)
        )
    }
}

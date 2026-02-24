import SwiftUI

// MARK: - Body Double View

/// 44×44pt pixel-art canvas figure: a person sitting at a laptop.
/// Animation speed and mood indicator adapt to CompanionMood.
struct BodyDoubleView: View {
    let mood: CompanionMood

    @State private var phase: Double = 0   // 0→1 looping, drives arm/head movement
    @State private var blink: Bool = false

    private var typingDuration: Double {
        switch mood {
        case .happy, .proud, .energized: return 0.7
        case .neutral:                   return 1.1
        case .worried:                   return 1.6
        case .disappointed:              return 2.2
        }
    }

    var body: some View {
        Canvas { ctx, size in
            drawFigure(ctx, size: size, phase: phase, blink: blink, mood: mood)
        }
        .frame(width: 44, height: 44)
        .onAppear {
            withAnimation(.linear(duration: typingDuration).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
            startBlinkTimer()
        }
    }

    // MARK: - Blink Timer

    private func startBlinkTimer() {
        // Schedule recurring blink every ~3.5 seconds
        func scheduleBlink() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                blink = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    blink = false
                    scheduleBlink()
                }
            }
        }
        scheduleBlink()
    }

    // MARK: - Drawing

    private func drawFigure(
        _ ctx: GraphicsContext,
        size: CGSize,
        phase: Double,
        blink: Bool,
        mood: CompanionMood
    ) {
        let w = size.width
        let h = size.height
        let s = min(w, h)
        let scale = s / 44.0

        // Pixel-art colors
        let skinColor = Color(red: 0.95, green: 0.80, blue: 0.65)
        let bodyColor = Color(red: 0.35, green: 0.45, blue: 0.90)
        let hairColor = Color(red: 0.25, green: 0.18, blue: 0.12)
        let laptopColor = Color(red: 0.30, green: 0.30, blue: 0.35)
        let screenColor = Color(red: 0.45, green: 0.75, blue: 0.95)
        let keyboardColor = Color(red: 0.40, green: 0.40, blue: 0.45)

        let sinVal = sin(phase * 2 * .pi)

        // Helper: fill rect
        func fillRect(x: CGFloat, y: CGFloat, w rw: CGFloat, h rh: CGFloat, color: Color) {
            let rect = CGRect(x: x * scale, y: y * scale, width: rw * scale, height: rh * scale)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 1 * scale), with: .color(color))
        }

        // Helper: fill circle
        func fillCircle(cx: CGFloat, cy: CGFloat, r: CGFloat, color: Color) {
            let rect = CGRect(x: (cx - r) * scale, y: (cy - r) * scale,
                              width: r * 2 * scale, height: r * 2 * scale)
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
        }

        // Mood indicator above head
        switch mood {
        case .happy, .proud:
            fillCircle(cx: 22, cy: 3, r: 3, color: .green.opacity(0.85))
            // Draw a tiny heart hint – just a bright dot
        case .worried:
            fillRect(x: 20, y: 1, w: 4, h: 5, color: .orange.opacity(0.9))
        case .disappointed:
            fillRect(x: 19, y: 1, w: 6, h: 2, color: .gray.opacity(0.7))
            fillRect(x: 20, y: 3, w: 4, h: 2, color: .gray.opacity(0.5))
        default:
            break  // neutral / energized: no indicator
        }

        // Head (bobs slightly with phase)
        let headY: CGFloat = 7 + sinVal * 1.0
        fillRect(x: 17, y: headY, w: 10, h: 10, color: skinColor)

        // Hair
        fillRect(x: 17, y: headY, w: 10, h: 3, color: hairColor)

        // Eyes
        if blink {
            fillRect(x: 19, y: headY + 4, w: 2, h: 0.5, color: hairColor)
            fillRect(x: 23, y: headY + 4, w: 2, h: 0.5, color: hairColor)
        } else {
            fillRect(x: 19, y: headY + 4, w: 2, h: 2, color: hairColor)
            fillRect(x: 23, y: headY + 4, w: 2, h: 2, color: hairColor)
        }

        // Torso
        let torsoY: CGFloat = headY + 10
        fillRect(x: 16, y: torsoY, w: 12, h: 12, color: bodyColor)

        // Left arm (typing movement)
        let armEndY: CGFloat = torsoY + 10 + sinVal * 2.5
        var leftArm = Path()
        leftArm.move(to: CGPoint(x: 16 * scale, y: (torsoY + 4) * scale))
        leftArm.addLine(to: CGPoint(x: 10 * scale, y: armEndY * scale))
        ctx.stroke(leftArm, with: .color(skinColor), lineWidth: 3 * scale)

        // Right arm (typing movement, offset phase)
        let armEndYR: CGFloat = torsoY + 10 - sinVal * 2.5
        var rightArm = Path()
        rightArm.move(to: CGPoint(x: 28 * scale, y: (torsoY + 4) * scale))
        rightArm.addLine(to: CGPoint(x: 34 * scale, y: armEndYR * scale))
        ctx.stroke(rightArm, with: .color(skinColor), lineWidth: 3 * scale)

        // Laptop keyboard (base)
        fillRect(x: 8, y: 34, w: 28, h: 4, color: keyboardColor)

        // Laptop screen (slightly tilted trapezoid – approximated as rect)
        let screenY: CGFloat = 24
        fillRect(x: 10, y: screenY, w: 24, h: 10, color: laptopColor)
        fillRect(x: 11, y: screenY + 1, w: 22, h: 7, color: screenColor.opacity(0.8))

        // Screen glow lines (simulating code / text)
        let glowOpacity = 0.5 + sinVal * 0.2
        fillRect(x: 12, y: screenY + 2, w: CGFloat(8 + Int(sinVal * 4 + 4)), h: 1,
                 color: .white.opacity(glowOpacity))
        fillRect(x: 12, y: screenY + 4, w: 14, h: 1, color: .white.opacity(glowOpacity * 0.7))
        fillRect(x: 12, y: screenY + 6, w: 10, h: 1, color: .white.opacity(glowOpacity * 0.5))
    }
}

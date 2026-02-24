import SwiftUI

// MARK: - Garden View

/// A Canvas-drawn garden visualization that reflects the user's productivity.
/// - Productive work grows the plant/garden
/// - Neutral maintains status quo
/// - Harmful work grows thorns and weeds
/// In faith mode, high productivity adds a golden shimmer effect.
struct GardenView: View {
    /// Focus score 0-100 determines garden health
    let score: Int
    /// Whether faith mode is active (for golden shimmer)
    let isFaithMode: Bool
    /// Size variant
    let size: GardenSize

    enum GardenSize {
        case small   // Menu bar icon ~20px
        case medium  // Widget ~80px
        case large   // Statistics ~200px
    }

    @State private var animationPhase: Double = 0
    @State private var shimmerPhase: Double = 0

    private var canvasSize: CGFloat {
        switch size {
        case .small: return 20
        case .medium: return 80
        case .large: return 200
        }
    }

    var body: some View {
        Canvas { context, cgSize in
            let w = cgSize.width
            let h = cgSize.height
            let groundY = h * 0.82

            // Background sky gradient
            if size != .small {
                drawSky(context: context, size: cgSize, score: score)
            }

            // Ground
            drawGround(context: context, size: cgSize, groundY: groundY, score: score)

            // Main plant/tree
            drawPlant(context: context, size: cgSize, groundY: groundY, score: score)

            // Thorns and weeds (low score)
            if score < 40 {
                drawThorns(context: context, size: cgSize, groundY: groundY, severity: Double(40 - score) / 40.0)
            }

            // Flowers and butterflies (high score)
            if score > 65 {
                drawFlowers(context: context, size: cgSize, groundY: groundY, abundance: Double(score - 65) / 35.0)
            }

            // Golden shimmer for faith mode
            if isFaithMode && score > 80 {
                drawGoldenShimmer(context: context, size: cgSize, intensity: Double(score - 80) / 20.0)
            }
        }
        .frame(width: canvasSize, height: canvasSize)
        .clipShape(RoundedRectangle(cornerRadius: size == .small ? 4 : 12))
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
            if isFaithMode {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    shimmerPhase = 1
                }
            }
        }
    }

    // MARK: - Sky

    private func drawSky(context: GraphicsContext, size: CGSize, score: Int) {
        let skyColor: Color = score > 60
            ? Color(red: 0.1, green: 0.15, blue: 0.3)
            : Color(red: 0.15, green: 0.1, blue: 0.2)

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(skyColor)
        )

        // Stars for high scores
        if score > 70 && size == .large {
            for i in 0..<5 {
                let x = CGFloat(i) * size.width / 5 + 15
                let y = CGFloat(10 + (i * 7) % 30)
                let starSize: CGFloat = 2
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                    with: .color(.white.opacity(0.6))
                )
            }
        }
    }

    // MARK: - Ground

    private func drawGround(context: GraphicsContext, size: CGSize, groundY: CGFloat, score: Int) {
        let groundColor: Color = score > 50
            ? Color(red: 0.15, green: 0.3, blue: 0.1)   // Healthy green soil
            : Color(red: 0.25, green: 0.15, blue: 0.1)   // Dry brown soil

        let groundPath = Path { path in
            path.move(to: CGPoint(x: 0, y: groundY))
            // Gentle hill
            path.addQuadCurve(
                to: CGPoint(x: size.width, y: groundY),
                control: CGPoint(x: size.width / 2, y: groundY - size.height * 0.05)
            )
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }
        context.fill(groundPath, with: .color(groundColor))
    }

    // MARK: - Plant / Tree

    private func drawPlant(context: GraphicsContext, size: CGSize, groundY: CGFloat, score: Int) {
        let centerX = size.width / 2
        let trunkHeight = size.height * 0.35 * (0.5 + Double(min(score, 100)) / 200.0)
        let trunkWidth = size.width * 0.04

        // Trunk
        let trunkColor: Color = score > 40
            ? Color(red: 0.35, green: 0.22, blue: 0.1)
            : Color(red: 0.25, green: 0.15, blue: 0.08)

        let trunkPath = Path { path in
            path.addRoundedRect(
                in: CGRect(
                    x: centerX - trunkWidth / 2,
                    y: groundY - trunkHeight,
                    width: trunkWidth,
                    height: trunkHeight
                ),
                cornerSize: CGSize(width: 2, height: 2)
            )
        }
        context.fill(trunkPath, with: .color(trunkColor))

        // Canopy / Leaves
        let canopyRadius = size.width * 0.15 * (0.4 + Double(min(score, 100)) / 166.0)
        let canopyY = groundY - trunkHeight - canopyRadius * 0.3

        if score > 20 {
            let leafColor: Color = score > 60
                ? Color(red: 0.1, green: 0.55, blue: 0.15)   // Lush green
                : score > 40
                    ? Color(red: 0.3, green: 0.45, blue: 0.15) // Fading green
                    : Color(red: 0.45, green: 0.35, blue: 0.15) // Yellow/dying

            // Main canopy circle
            context.fill(
                Path(ellipseIn: CGRect(
                    x: centerX - canopyRadius,
                    y: canopyY - canopyRadius,
                    width: canopyRadius * 2,
                    height: canopyRadius * 1.6
                )),
                with: .color(leafColor)
            )

            // Side canopy clusters
            if score > 50 {
                let sideOffset = canopyRadius * 0.7
                for xOff in [-sideOffset, sideOffset] {
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: centerX + xOff - canopyRadius * 0.6,
                            y: canopyY - canopyRadius * 0.5,
                            width: canopyRadius * 1.2,
                            height: canopyRadius * 1.0
                        )),
                        with: .color(leafColor.opacity(0.85))
                    )
                }
            }
        }

        // Branches for low score (bare tree)
        if score <= 20 {
            let branchColor = Color(red: 0.3, green: 0.2, blue: 0.1)
            let branchTop = groundY - trunkHeight

            for angle in [-0.5, 0.3, -0.2, 0.6] {
                let branchLength = size.width * 0.08
                let endX = centerX + CGFloat(angle) * branchLength * 2
                let endY = branchTop - branchLength

                var branchPath = Path()
                branchPath.move(to: CGPoint(x: centerX, y: branchTop + branchLength * 0.3))
                branchPath.addLine(to: CGPoint(x: endX, y: endY))
                context.stroke(branchPath, with: .color(branchColor), lineWidth: 1.5)
            }
        }
    }

    // MARK: - Thorns & Weeds

    private func drawThorns(context: GraphicsContext, size: CGSize, groundY: CGFloat, severity: Double) {
        let thornColor = Color(red: 0.4, green: 0.2, blue: 0.1)
        let thornCount = Int(severity * 6) + 1

        for i in 0..<thornCount {
            let x = size.width * (0.1 + Double(i) * 0.15)
            let height = size.height * 0.08 * (0.5 + severity * 0.5)

            var thornPath = Path()
            // Zigzag thorn shape
            thornPath.move(to: CGPoint(x: x, y: groundY))
            thornPath.addLine(to: CGPoint(x: x - 3, y: groundY - height * 0.5))
            thornPath.addLine(to: CGPoint(x: x + 2, y: groundY - height * 0.7))
            thornPath.addLine(to: CGPoint(x: x - 1, y: groundY - height))
            context.stroke(thornPath, with: .color(thornColor), lineWidth: 1.5)

            // Thorn spikes
            let spikeY = groundY - height * 0.5
            var spikePath = Path()
            spikePath.move(to: CGPoint(x: x - 2, y: spikeY))
            spikePath.addLine(to: CGPoint(x: x - 6, y: spikeY - 3))
            spikePath.move(to: CGPoint(x: x + 1, y: spikeY + 4))
            spikePath.addLine(to: CGPoint(x: x + 5, y: spikeY + 1))
            context.stroke(spikePath, with: .color(thornColor.opacity(0.8)), lineWidth: 1)
        }

        // Red warning weeds
        if severity > 0.5 {
            let weedColor = Color(red: 0.6, green: 0.15, blue: 0.1)
            for i in 0..<3 {
                let x = size.width * (0.2 + Double(i) * 0.3)
                context.fill(
                    Path(ellipseIn: CGRect(x: x - 3, y: groundY - 4, width: 6, height: 4)),
                    with: .color(weedColor.opacity(0.6))
                )
            }
        }
    }

    // MARK: - Flowers

    private func drawFlowers(context: GraphicsContext, size: CGSize, groundY: CGFloat, abundance: Double) {
        let flowerCount = Int(abundance * 5) + 1
        let colors: [Color] = [.pink, .yellow, .orange, .purple, .white]

        for i in 0..<flowerCount {
            let x = size.width * (0.15 + Double(i) * 0.17)
            let stemHeight = size.height * 0.06
            let flowerSize: CGFloat = size.width * 0.025

            // Stem
            var stemPath = Path()
            stemPath.move(to: CGPoint(x: x, y: groundY))
            stemPath.addLine(to: CGPoint(x: x, y: groundY - stemHeight))
            context.stroke(stemPath, with: .color(.green.opacity(0.6)), lineWidth: 1)

            // Flower petals
            let color = colors[i % colors.count]
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - flowerSize,
                    y: groundY - stemHeight - flowerSize,
                    width: flowerSize * 2,
                    height: flowerSize * 2
                )),
                with: .color(color.opacity(0.8))
            )

            // Center
            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - flowerSize * 0.3,
                    y: groundY - stemHeight - flowerSize * 0.3,
                    width: flowerSize * 0.6,
                    height: flowerSize * 0.6
                )),
                with: .color(.yellow)
            )
        }
    }

    // MARK: - Golden Shimmer (Faith Mode)

    private func drawGoldenShimmer(context: GraphicsContext, size: CGSize, intensity: Double) {
        let shimmerColor = Color(red: 1.0, green: 0.85, blue: 0.3)
        let particleCount = Int(intensity * 8) + 3

        for i in 0..<particleCount {
            let phase = Double(i) / Double(particleCount)
            let x = size.width * (0.2 + phase * 0.6)
            let y = size.height * (0.15 + sin(phase * .pi * 2 + animationPhase * .pi) * 0.15)
            let particleSize: CGFloat = size.width * 0.015 * CGFloat(intensity)

            context.fill(
                Path(ellipseIn: CGRect(
                    x: x - particleSize,
                    y: y - particleSize,
                    width: particleSize * 2,
                    height: particleSize * 2
                )),
                with: .color(shimmerColor.opacity(0.3 + intensity * 0.4))
            )
        }

        // Outer glow
        let glowRect = CGRect(
            x: size.width * 0.15,
            y: size.height * 0.1,
            width: size.width * 0.7,
            height: size.height * 0.6
        )
        context.fill(
            Path(ellipseIn: glowRect),
            with: .color(shimmerColor.opacity(0.05 + intensity * 0.08))
        )
    }
}

// MARK: - Garden Icon (Menu Bar)

/// Small garden icon for the menu bar that shows plant health
struct GardenMenuBarIcon: View {
    let score: Int

    var body: some View {
        Image(systemName: gardenSymbol)
            .font(.system(size: 12))
            .foregroundStyle(gardenColor)
    }

    private var gardenSymbol: String {
        if score >= 70 { return "leaf.fill" }
        if score >= 40 { return "leaf" }
        return "leaf.arrow.triangle.circlepath"
    }

    private var gardenColor: Color {
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }
}

import SwiftUI

// MARK: - Focus Score View

/// Circular progress indicator showing the daily focus score (0-100).
struct FocusScoreView: View {
    let score: Int
    let size: CGFloat

    init(score: Int, size: CGFloat = 50) {
        self.score = max(0, min(100, score))
        self.size = size
    }

    private var scoreColor: Color {
        if score >= 75 { return .green }
        if score >= 50 { return .blue }
        if score >= 25 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: size * 0.08)

            // Score ring
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: score)

            // Score text
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if size >= 50 {
                    Text("Score")
                        .font(.system(size: size * 0.14))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

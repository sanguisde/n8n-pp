import SwiftUI

// MARK: - Day Blocks View

/// Linear timeline showing today's 15-minute blocks color-coded by category.
/// Green = productive, Gray = neutral, Red = harmful, Empty = not yet logged.
struct DayBlocksView: View {
    /// Today's entries sorted by timestamp
    let entries: [TimeEntry]
    /// Interval in minutes (for block sizing)
    let intervalMinutes: Int
    /// Compact mode for widget
    var compact: Bool = false

    /// The hours to display (typically waking hours)
    private let startHour = 6
    private let endHour = 23

    private var totalBlocks: Int {
        (endHour - startHour) * (60 / intervalMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            if !compact {
                Text("Tagesverlauf")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            // Block timeline
            GeometryReader { geo in
                let blockWidth = geo.size.width / CGFloat(totalBlocks)
                let blockHeight: CGFloat = compact ? 8 : 14

                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ThemeColors.cardBackground)
                        .frame(height: blockHeight)

                    // Blocks
                    HStack(spacing: 0) {
                        ForEach(0..<totalBlocks, id: \.self) { index in
                            let color = colorForBlock(index: index)
                            Rectangle()
                                .fill(color)
                                .frame(width: max(1, blockWidth - 0.5), height: blockHeight)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                    // Current time marker
                    currentTimeMarker(totalWidth: geo.size.width, height: blockHeight)
                }
            }
            .frame(height: compact ? 8 : 14)

            // Hour labels
            if !compact {
                hourLabels
            }
        }
    }

    // MARK: - Block Color

    private func colorForBlock(index: Int) -> Color {
        let calendar = Calendar.current
        let blockStartHour = startHour + (index * intervalMinutes) / 60
        let blockStartMinute = (index * intervalMinutes) % 60

        // Check if this block is in the future
        let now = Date.now
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        if blockStartHour > currentHour || (blockStartHour == currentHour && blockStartMinute > currentMinute) {
            return ThemeColors.cardBackground.opacity(0.3)
        }

        // Find entry matching this block
        let entry = entries.first { entry in
            let entryHour = calendar.component(.hour, from: entry.timestamp)
            let entryMinute = calendar.component(.minute, from: entry.timestamp)

            // Match within the block time window
            let entryTotalMin = entryHour * 60 + entryMinute
            let blockTotalMin = blockStartHour * 60 + blockStartMinute
            return entryTotalMin >= blockTotalMin && entryTotalMin < blockTotalMin + intervalMinutes
        }

        if let entry = entry, let category = entry.activityCategory {
            return category.color.opacity(0.8)
        }

        // Past but unlogged
        return ThemeColors.subtleBorder
    }

    // MARK: - Current Time Marker

    private func currentTimeMarker(totalWidth: CGFloat, height: CGFloat) -> some View {
        let calendar = Calendar.current
        let now = Date.now
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let totalMinutesFromStart = (currentHour - startHour) * 60 + currentMinute
        let totalMinutesInRange = (endHour - startHour) * 60
        let progress = CGFloat(totalMinutesFromStart) / CGFloat(totalMinutesInRange)
        let xPosition = totalWidth * min(1, max(0, progress))

        return Rectangle()
            .fill(.white.opacity(0.8))
            .frame(width: 1.5, height: height + 4)
            .offset(x: xPosition - 0.75, y: -2)
            .opacity(progress >= 0 && progress <= 1 ? 1 : 0)
    }

    // MARK: - Hour Labels

    private var hourLabels: some View {
        HStack {
            ForEach([6, 9, 12, 15, 18, 21], id: \.self) { hour in
                Text("\(hour)h")
                    .font(.system(size: 8))
                    .foregroundStyle(ThemeColors.textTertiary)
                if hour != 21 {
                    Spacer()
                }
            }
        }
    }
}

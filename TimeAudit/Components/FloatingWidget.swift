import AppKit
import SwiftUI

// MARK: - Floating Widget

/// A small, always-on-top desktop widget for quick time logging.
/// Stays floating above all windows. Becomes key when clicked so text
/// fields receive keyboard input, but does not steal focus on show.
/// Position is persisted across app launches via UserDefaults.
final class FloatingWidget: NSPanel {

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 200),
            styleMask: [.fullSizeContentView],   // no .nonactivatingPanel → can become key
            backing: .buffered,
            defer: false
        )

        // Always on top, visible on all spaces
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow

        // Blur background + SwiftUI content
        let blurView = NSVisualEffectView()
        blurView.material = .underWindowBackground
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 14
        blurView.layer?.masksToBounds = true
        blurView.layer?.borderWidth = 0.5
        blurView.layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor

        let hostingView = NSHostingView(rootView: contentView
            .preferredColorScheme(.dark)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        blurView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: blurView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
        ])

        self.contentView = blurView

        restorePosition()
    }

    /// NSPanel with .fullSizeContentView but without .nonactivatingPanel
    /// must explicitly declare it can become key so text fields work.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }   // don't replace the main window

    /// Show without stealing focus from the currently active app.
    func present() {
        // orderFront keeps the panel visible without activating the app.
        // When the user clicks inside, canBecomeKey=true lets it receive keyboard events.
        orderFront(nil)
    }

    /// Hide without destroying.
    func hideWidget() {
        orderOut(nil)
    }

    // MARK: - Position Persistence

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        savePosition()
    }

    private func savePosition() {
        UserDefaults.standard.set(frame.origin.x, forKey: "widgetPosX")
        UserDefaults.standard.set(frame.origin.y, forKey: "widgetPosY")
    }

    private func restorePosition() {
        let x = UserDefaults.standard.double(forKey: "widgetPosX")
        let y = UserDefaults.standard.double(forKey: "widgetPosY")

        if x != 0 || y != 0 {
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // Default: bottom-right corner of main screen
            if let screen = NSScreen.main {
                let f = screen.visibleFrame
                setFrameOrigin(NSPoint(x: f.maxX - frame.width - 20, y: f.minY + 20))
            }
        }
    }
}

import AppKit
import SwiftUI

// MARK: - Floating Widget

/// A small, always-on-top desktop widget for quick time logging.
/// Uses NSVisualEffectView for a translucent blur background.
/// Position is persisted across app launches via UserDefaults.
final class FloatingWidget: NSPanel {

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 200),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
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

        // Build the content: blur background + SwiftUI view
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

        // Restore saved position or place in bottom-right
        restorePosition()
    }

    /// Show the widget
    func present() {
        orderFront(nil)
    }

    /// Hide the widget (don't destroy)
    func hideWidget() {
        orderOut(nil)
    }

    // MARK: - Position Persistence

    /// Save position whenever the widget is moved
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        savePosition()
    }

    private func savePosition() {
        let origin = frame.origin
        UserDefaults.standard.set(origin.x, forKey: "widgetPosX")
        UserDefaults.standard.set(origin.y, forKey: "widgetPosY")
    }

    private func restorePosition() {
        let x = UserDefaults.standard.double(forKey: "widgetPosX")
        let y = UserDefaults.standard.double(forKey: "widgetPosY")

        if x != 0 || y != 0 {
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // Default: bottom-right of main screen
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let widgetX = screenFrame.maxX - frame.width - 20
                let widgetY = screenFrame.minY + 20
                setFrameOrigin(NSPoint(x: widgetX, y: widgetY))
            }
        }
    }
}

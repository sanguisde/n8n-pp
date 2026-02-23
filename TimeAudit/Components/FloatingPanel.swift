import AppKit
import SwiftUI

// MARK: - Floating Panel

/// A floating NSPanel subclass that hosts a SwiftUI view.
/// Used for the logging popup - stays on top, non-activating, cannot be dismissed without selection.
final class FloatingPanel<Content: View>: NSPanel {
    /// Whether the panel is allowed to close (set to true after a category is selected)
    var canDismiss: Bool = false

    init(contentView: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 560),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled, .closable],
            backing: .buffered,
            defer: false
        )

        // Panel configuration
        level = .floating
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isOpaque = false
        backgroundColor = .clear
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow

        // Host the SwiftUI view
        let hostingView = NSHostingView(rootView: contentView
            .preferredColorScheme(.dark)
        )
        self.contentView = hostingView

        // Center on screen
        center()
    }

    /// Override close to prevent dismissal without selection
    override func close() {
        guard canDismiss else { return }
        super.close()
    }

    /// Override performClose to prevent Cmd+W dismissal
    override func performClose(_ sender: Any?) {
        guard canDismiss else { return }
        super.performClose(sender)
    }

    /// Show the panel and bring it to front
    func present() {
        canDismiss = false
        center()
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Allow dismissal and close
    func dismiss() {
        canDismiss = true
        close()
    }
}

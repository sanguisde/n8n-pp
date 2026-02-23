import Foundation
import AppKit

// MARK: - Sound Player

/// Plays notification sounds for timer popups.
struct SoundPlayer {
    /// Play the default notification sound
    static func playNotification() {
        NSSound.beep()
    }

    /// Play a specific system sound
    static func playSystemSound(named name: String = "Tink") {
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}

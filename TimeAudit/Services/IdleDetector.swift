import Foundation
import IOKit

// MARK: - Idle Detector

/// Detects system idle time using IOKit's HIDIdleTime property.
/// Polls the system to determine how long since the user last interacted (mouse/keyboard).
final class IdleDetector: ObservableObject {
    /// Current system idle time in seconds
    @Published var idleTimeSeconds: TimeInterval = 0

    /// Whether the system is considered idle (> threshold)
    @Published var isIdle: Bool = false

    /// Idle threshold in seconds (default: 5 minutes)
    var idleThresholdSeconds: TimeInterval = 300

    private var pollTimer: Timer?

    /// Start polling for idle time every `interval` seconds
    func startPolling(interval: TimeInterval = 30) {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.update()
        }
        // Also run immediately
        update()
    }

    /// Stop polling
    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// Read the current system idle time from IOKit
    func getSystemIdleTime() -> TimeInterval {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &iterator
        )

        guard result == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }

        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return 0 }
        defer { IOObjectRelease(entry) }

        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        let kr = IORegistryEntryCreateCFProperties(entry, &unmanagedDict, kCFAllocatorDefault, 0)
        guard kr == KERN_SUCCESS, let dict = unmanagedDict?.takeRetainedValue() as? [String: Any] else {
            return 0
        }

        guard let idleTime = dict["HIDIdleTime"] as? Int64 else { return 0 }

        // HIDIdleTime is in nanoseconds, convert to seconds
        return TimeInterval(idleTime) / TimeInterval(NSEC_PER_SEC)
    }

    private func update() {
        let idle = getSystemIdleTime()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.idleTimeSeconds = idle
            self.isIdle = idle >= self.idleThresholdSeconds
        }
    }

    deinit {
        stopPolling()
    }
}

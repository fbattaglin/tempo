import Foundation

/// A single scheduled beat, expressed in host time (the same timebase as
/// `mach_absolute_time` / `CACurrentMediaTime`), so the UI can align to it
/// without ever touching the audio engine's sample clock directly.
struct BeatEvent: Equatable {
    let index: Int
    let hostTime: UInt64
    let isAccent: Bool
}

/// The last two scheduled beats. The animation interpolates between them.
struct BeatWindow: Equatable {
    var previous: BeatEvent?
    var next: BeatEvent?
}

/// Single source of truth for the relationship between audio sample time
/// and host (wall-clock) time. The audio scheduler is the only writer;
/// SwiftUI views are readers. Access is synchronized with a lock because
/// the writer runs on a real-time audio/scheduling thread and the reader
/// runs on the main thread's display link — neither may block on the other
/// for long, so this is a tiny, contention-free critical section.
final class BeatClock {
    private let lock = NSLock()
    private var _window = BeatWindow()
    private let timebase: mach_timebase_info_data_t

    init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        timebase = info
    }

    var window: BeatWindow {
        lock.lock()
        defer { lock.unlock() }
        return _window
    }

    func publish(_ event: BeatEvent) {
        lock.lock()
        _window.previous = _window.next
        _window.next = event
        lock.unlock()
    }

    func reset() {
        lock.lock()
        _window = BeatWindow()
        lock.unlock()
    }

    /// Converts a host-time tick count (mach_absolute_time domain) to
    /// seconds since boot — the same timeline as `CACurrentMediaTime()`.
    func seconds(fromHostTime hostTime: UInt64) -> Double {
        Double(hostTime) * Double(timebase.numer) / Double(timebase.denom) / 1_000_000_000
    }

    /// Converts a duration in seconds to host-time ticks, for offsetting
    /// an anchor host time by a computed delta.
    func hostTicks(fromSeconds seconds: Double) -> UInt64 {
        guard seconds > 0 else { return 0 }
        let ticks = seconds * 1_000_000_000 * Double(timebase.denom) / Double(timebase.numer)
        return UInt64(ticks)
    }

    func nowHostTime() -> UInt64 {
        mach_absolute_time()
    }
}

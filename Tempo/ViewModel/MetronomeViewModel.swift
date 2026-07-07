import Foundation
import Combine
import QuartzCore

@MainActor
final class MetronomeViewModel: ObservableObject {
    static let bpmRange: ClosedRange<Double> = 30...240
    /// Used only the very first time the app ever launches, before the user
    /// has a chance to set their own default in Settings. 90 BPM ("andante",
    /// a comfortable walking pace) is a gentler starting point than the
    /// classic 120 BPM metronome default.
    static let factoryDefaultBPM: Double = 90

    @Published var bpm: Double {
        didSet {
            guard bpm != oldValue else { return }
            bpm = bpm.clamped(to: Self.bpmRange)
            engine.updateBPM(bpm)
            defaults.set(bpm, forKey: Keys.bpm)
        }
    }

    /// The BPM that the reset button / ⌘0 restore, and that a fresh install
    /// starts at. Configurable in Settings — persisted independently from
    /// the last-used `bpm` so it survives across sessions untouched.
    @Published var defaultBPM: Double {
        didSet {
            guard defaultBPM != oldValue else { return }
            defaultBPM = defaultBPM.clamped(to: Self.bpmRange)
            defaults.set(defaultBPM, forKey: Keys.defaultBPM)
        }
    }

    @Published private(set) var isPlaying = false

    @Published var timeSignature: TimeSignature {
        didSet {
            guard timeSignature != oldValue else { return }
            engine.updateBeatsPerBar(timeSignature.beatsPerBar)
            defaults.set(timeSignature.label, forKey: Keys.timeSignature)
        }
    }

    var beatClock: BeatClock { engine.beatClock }

    private let engine = MetronomeEngine()
    private let defaults = UserDefaults.standard
    private var tapTimestamps: [CFTimeInterval] = []
    private let maxTapGap: CFTimeInterval = 2.0

    private enum Keys {
        static let bpm = "tempo.bpm"
        static let timeSignature = "tempo.timeSignature"
        static let defaultBPM = "tempo.defaultBPM"
    }

    init() {
        let storedDefaultBPM = defaults.object(forKey: Keys.defaultBPM) as? Double
        let resolvedDefaultBPM = (storedDefaultBPM ?? Self.factoryDefaultBPM).clamped(to: Self.bpmRange)
        self.defaultBPM = resolvedDefaultBPM

        let storedBPM = defaults.object(forKey: Keys.bpm) as? Double
        self.bpm = (storedBPM ?? resolvedDefaultBPM).clamped(to: Self.bpmRange)

        let storedLabel = defaults.string(forKey: Keys.timeSignature)
        self.timeSignature = TimeSignature.common.first { $0.label == storedLabel } ?? .default
    }

    func togglePlayback() {
        isPlaying ? stop() : play()
    }

    func play() {
        guard !isPlaying else { return }
        isPlaying = engine.start(bpm: bpm, beatsPerBar: timeSignature.beatsPerBar)
    }

    func stop() {
        guard isPlaying else { return }
        engine.stop()
        isPlaying = false
    }

    func nudgeBPM(by delta: Double) {
        bpm = bpm + delta
    }

    func resetBPMToDefault() {
        bpm = defaultBPM
    }

    /// Lets the user adopt whatever tempo they're currently at as their new
    /// default, from Settings — no need to type a number.
    func setCurrentBPMAsDefault() {
        defaultBPM = bpm
    }

    /// Registers a tap-tempo hit. Averages recent inter-tap intervals so
    /// the estimate settles quickly but isn't thrown off by a single
    /// irregular tap.
    func registerTap() {
        let now = CACurrentMediaTime()
        tapTimestamps.removeAll { now - $0 > maxTapGap }
        tapTimestamps.append(now)
        tapTimestamps = Array(tapTimestamps.suffix(6))

        guard tapTimestamps.count >= 2 else { return }
        let intervals = zip(tapTimestamps.dropFirst(), tapTimestamps).map(-)
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        guard averageInterval > 0 else { return }
        bpm = 60.0 / averageInterval
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

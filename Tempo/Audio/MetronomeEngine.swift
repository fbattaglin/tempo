import AVFoundation

/// Drives click playback with sample-accurate scheduling on `AVAudioEngine`.
///
/// The engine never relies on a wall-clock timer to *trigger* sound. A
/// background timer only decides *when to look ahead*; the actual playback
/// instant is always expressed as a sample position handed to
/// `AVAudioPlayerNode.scheduleBuffer(_:at:)`, so the real-time audio render
/// thread — not this process's scheduling jitter — determines exactly when
/// each click sounds. A running fractional accumulator (`nextBeatSampleTime`)
/// means rounding to the nearest sample never compounds into audible drift,
/// even after playing for a long time.
///
/// The `AVAudioEngine` is kept running for the lifetime of the object: pausing
/// only stops the scheduler and the player node, never the engine. This keeps
/// the render sample-clock monotonic and always valid, so resuming can simply
/// re-anchor to the current render position instead of racing an engine
/// restart (which used to leave `nextBeatSampleTime` stranded far in the past,
/// silencing every subsequent beat).
///
/// Every scheduled beat is also published to `beatClock` as a host-time
/// event, so the pendulum animation can align to the exact same instants
/// without deriving its own notion of tempo.
final class MetronomeEngine {
    let beatClock = BeatClock()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var normalBuffer: AVAudioPCMBuffer!
    private var accentBuffer: AVAudioPCMBuffer!
    private var sampleRate: Double = 44_100

    private let scheduleQueue = DispatchQueue(label: "com.fabianobattaglin.tempo.scheduler", qos: .userInteractive)
    private var schedulerTimer: DispatchSourceTimer?
    private var backgroundActivity: NSObjectProtocol?

    private(set) var isRunning = false

    // Scheduling state — touched only on `scheduleQueue`.
    private var nextBeatSampleTime: Double = 0
    private var nextBeatIndex: Int = 0
    private var samplesPerBeat: Double = 0
    private var pendingSamplesPerBeat: Double?
    private var beatsPerBar: Int = 4
    // When true, the next scheduler tick captures a fresh anchor from the same
    // `lastRenderTime` read it uses for the current sample position — so the
    // beat timeline and the render clock can never disagree.
    private var needsAnchor = false
    // Set right before `needsAnchor` on each `start()`, so the anchoring tick
    // knows how much lead time to leave before the first click.
    private var pendingLeadIn: Double = 0
    private var anchorNodeSampleTime: Double = 0
    private var anchorHostTime: UInt64 = 0

    private static let lookAheadInterval: TimeInterval = 0.02
    private static let lookAheadWindow: Double = 0.25 // seconds of audio scheduled in advance
    // A cold engine start (first play of the app's lifetime) can have real
    // hardware/driver wake-up latency, so it gets a generous lead-in. Every
    // resume after that finds the engine already warm and running — the
    // clock stays valid throughout a pause — so it only needs enough lead
    // time to clear the scheduling round-trip, keeping pause/resume snappy.
    private static let coldStartLeadIn: Double = 0.12
    private static let warmResumeLeadIn: Double = 0.03

    init() {
        engine.attach(playerNode)
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        sampleRate = format.sampleRate
        normalBuffer = ClickSynth.makeClickBuffer(format: format, accent: false)
        accentBuffer = ClickSynth.makeClickBuffer(format: format, accent: true)
    }

    deinit {
        engine.stop()
    }

    /// Returns `false` if the audio engine could not be started (e.g. no
    /// output device available), leaving `isRunning` unchanged so the caller
    /// can avoid presenting a "playing" UI state with no actual audio.
    @discardableResult
    func start(bpm: Double, beatsPerBar: Int) -> Bool {
        guard !isRunning else { return true }

        let wasAlreadyWarm = engine.isRunning
        guard startEngineIfNeeded() else { return false }

        playerNode.play()
        isRunning = true
        beatClock.reset()

        backgroundActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Metronome playback"
        )

        let leadIn = wasAlreadyWarm ? Self.warmResumeLeadIn : Self.coldStartLeadIn
        scheduleQueue.async { [weak self] in
            guard let self else { return }
            self.beatsPerBar = max(1, beatsPerBar)
            self.samplesPerBeat = self.sampleRate * 60.0 / bpm
            self.pendingSamplesPerBeat = nil
            self.nextBeatIndex = 0
            self.pendingLeadIn = leadIn
            self.needsAnchor = true
            self.startSchedulerLoop()
        }
        return true
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        schedulerTimer?.cancel()
        schedulerTimer = nil
        // Stop only the player node (this flushes buffers already scheduled
        // for the future); the engine keeps running so its sample-clock stays
        // valid and monotonic for the next `start()`.
        playerNode.stop()
        beatClock.reset()

        if let activity = backgroundActivity {
            ProcessInfo.processInfo.endActivity(activity)
            backgroundActivity = nil
        }
    }

    /// Applies a new tempo starting from the next beat that hasn't been
    /// scheduled yet, so an in-progress bar never audibly jumps.
    func updateBPM(_ bpm: Double) {
        let newSamplesPerBeat = sampleRate * 60.0 / bpm
        scheduleQueue.async { [weak self] in
            self?.pendingSamplesPerBeat = newSamplesPerBeat
        }
    }

    func updateBeatsPerBar(_ count: Int) {
        scheduleQueue.async { [weak self] in
            self?.beatsPerBar = max(1, count)
        }
    }

    @discardableResult
    private func startEngineIfNeeded() -> Bool {
        guard !engine.isRunning else { return true }
        do {
            try engine.start()
            return true
        } catch {
            // NSLog (not assertionFailure) so this is visible in Release
            // builds too, since a silent failure here used to leave the UI
            // showing "playing" with no audio and no diagnostic trail.
            NSLog("Tempo: failed to start AVAudioEngine: \(error)")
            return false
        }
    }

    private func startSchedulerLoop() {
        let timer = DispatchSource.makeTimerSource(queue: scheduleQueue)
        timer.schedule(deadline: .now(), repeating: Self.lookAheadInterval, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            self?.scheduleUpcomingBeats()
        }
        schedulerTimer = timer
        timer.resume()
    }

    private func scheduleUpcomingBeats() {
        guard let nodeTime = playerNode.lastRenderTime, nodeTime.isSampleTimeValid else { return }
        // `scheduleBuffer(at:)` interprets its sample time in the PLAYER
        // timeline, which resets to 0 on every `stop()`/`play()`. But
        // `lastRenderTime` is in the NODE (engine) timeline, which keeps
        // climbing for the whole engine lifetime. Scheduling against node
        // time works on the very first play (both clocks start near 0) but on
        // every resume it places the first click ~<engine-uptime> seconds in
        // the future — the classic AVAudioPlayerNode "60-second silence"
        // stall. Convert to player time so scheduling always lines up.
        guard let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
              playerTime.isSampleTimeValid else { return }

        let currentSample = Double(playerTime.sampleTime)

        if needsAnchor {
            anchorNodeSampleTime = currentSample
            anchorHostTime = nodeTime.isHostTimeValid ? nodeTime.hostTime : beatClock.nowHostTime()
            nextBeatSampleTime = currentSample + sampleRate * pendingLeadIn
            needsAnchor = false
        }

        let horizon = currentSample + sampleRate * Self.lookAheadWindow

        while nextBeatSampleTime < horizon {
            if let pending = pendingSamplesPerBeat {
                samplesPerBeat = pending
                pendingSamplesPerBeat = nil
            }

            let sampleTime = AVAudioFramePosition(nextBeatSampleTime.rounded())
            let avTime = AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
            let isAccent = nextBeatIndex % beatsPerBar == 0
            let buffer = isAccent ? accentBuffer! : normalBuffer!

            playerNode.scheduleBuffer(buffer, at: avTime, options: [], completionHandler: nil)

            let deltaSeconds = (Double(sampleTime) - anchorNodeSampleTime) / sampleRate
            let hostTime = anchorHostTime &+ beatClock.hostTicks(fromSeconds: deltaSeconds)
            beatClock.publish(BeatEvent(index: nextBeatIndex, hostTime: hostTime, isAccent: isAccent))

            nextBeatSampleTime += samplesPerBeat
            nextBeatIndex += 1
        }
    }
}

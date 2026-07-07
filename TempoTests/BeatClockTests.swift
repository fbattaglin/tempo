import XCTest
@testable import Tempo

final class BeatClockTests: XCTestCase {
    func testHostTimeRoundTripIsAccurate() {
        let clock = BeatClock()
        let seconds = 3.256
        let ticks = clock.hostTicks(fromSeconds: seconds)
        let roundTripped = clock.seconds(fromHostTime: ticks)
        XCTAssertEqual(roundTripped, seconds, accuracy: 0.0001)
    }

    /// Simulates the engine's scheduling loop: a fractional sample-time
    /// accumulator advanced by `samplesPerBeat` each iteration, rounded to
    /// the nearest integer sample only at the moment of scheduling. Verifies
    /// that after many beats the *average* tempo still matches the target
    /// exactly — i.e. per-beat rounding never compounds into audible drift.
    func testAccumulatedSchedulingDoesNotDrift() {
        let sampleRate = 44_100.0
        let bpm = 137.0 // deliberately not a round number
        let samplesPerBeat = sampleRate * 60.0 / bpm
        let beatCount = 10_000

        var nextBeatSampleTime = 0.0
        var scheduledSampleTimes: [Double] = []
        scheduledSampleTimes.reserveCapacity(beatCount)

        for _ in 0..<beatCount {
            scheduledSampleTimes.append(nextBeatSampleTime.rounded())
            nextBeatSampleTime += samplesPerBeat
        }

        let expectedFinalSampleTime = samplesPerBeat * Double(beatCount - 1)
        let actualFinalSampleTime = scheduledSampleTimes.last!

        // Rounding error per beat is at most 0.5 samples and does not
        // accumulate, so total drift across the whole run stays under a
        // single sample.
        XCTAssertEqual(actualFinalSampleTime, expectedFinalSampleTime, accuracy: 1.0)

        let actualDurationSeconds = actualFinalSampleTime / sampleRate
        let expectedDurationSeconds = expectedFinalSampleTime / sampleRate
        XCTAssertEqual(actualDurationSeconds, expectedDurationSeconds, accuracy: 0.0001)
    }

    func testBeatWindowPublishesMostRecentTwoEvents() {
        let clock = BeatClock()
        let first = BeatEvent(index: 0, hostTime: 100, isAccent: true)
        let second = BeatEvent(index: 1, hostTime: 200, isAccent: false)
        let third = BeatEvent(index: 2, hostTime: 300, isAccent: false)

        clock.publish(first)
        clock.publish(second)
        clock.publish(third)

        let window = clock.window
        XCTAssertEqual(window.previous, second)
        XCTAssertEqual(window.next, third)
    }
}

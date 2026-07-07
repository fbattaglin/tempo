import SwiftUI
import QuartzCore

/// A classic mechanical-metronome pendulum. Its motion is derived purely
/// from the beat instants published by `BeatClock` — never from an
/// independent timer — so it can never drift out of sync with the clicks.
/// The weight can be dragged along the rod to set BPM directly, mirroring
/// a real metronome.
struct PendulumView: View {
    @ObservedObject var viewModel: MetronomeViewModel

    // Drives redraws while playing. `TimelineView(.animation)` is the more
    // idiomatic choice here, but its schedule has been observed to stall
    // after only a couple of ticks on some systems; a plain 60Hz `Timer`
    // added to the `.common` run loop mode is a well-established fallback
    // that keeps ticking reliably (including during mouse tracking/drags),
    // and is fully invalidated whenever playback stops, so there's no
    // ongoing timer cost at rest.
    @State private var frameTick: UInt64 = 0
    @State private var displayTimer: Timer?

    private let canvasSize = CGSize(width: 220, height: 230)
    private let maxAngleDegrees: Double = 14
    private let rodLength: CGFloat = 176
    private let weightSize: CGFloat = 24
    private let minFraction: Double = 0.16
    private let maxFraction: Double = 0.92

    var body: some View {
        Canvas { context, size in
            _ = frameTick // establishes the redraw dependency
            draw(in: &context, size: size)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .accessibilityHidden(true)
        .onAppear { syncTimer(isPlaying: viewModel.isPlaying) }
        .onDisappear { syncTimer(isPlaying: false) }
        .onChange(of: viewModel.isPlaying) { isPlaying in
            syncTimer(isPlaying: isPlaying)
        }
    }

    private func syncTimer(isPlaying: Bool) {
        displayTimer?.invalidate()
        displayTimer = nil
        guard isPlaying else { return }

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in
            frameTick &+= 1
        }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
    }

    private var pivot: CGPoint {
        CGPoint(x: canvasSize.width / 2, y: canvasSize.height - 14)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let angle = currentAngleRadians()

        let tip = CGPoint(
            x: pivot.x + rodLength * sin(angle),
            y: pivot.y - rodLength * cos(angle)
        )

        var rod = Path()
        rod.move(to: pivot)
        rod.addLine(to: tip)
        context.stroke(rod, with: .color(.primary.opacity(0.8)), lineWidth: 3)

        let baseRect = CGRect(x: pivot.x - 6, y: pivot.y - 6, width: 12, height: 12)
        context.fill(Path(ellipseIn: baseRect), with: .color(.primary.opacity(0.8)))

        let fraction = weightFraction(forBPM: viewModel.bpm)
        let weightCenter = CGPoint(
            x: pivot.x + rodLength * fraction * sin(angle),
            y: pivot.y - rodLength * fraction * cos(angle)
        )
        let weightRect = CGRect(
            x: weightCenter.x - weightSize / 2,
            y: weightCenter.y - weightSize / 2,
            width: weightSize,
            height: weightSize
        )
        context.fill(Path(ellipseIn: weightRect), with: .color(.accentColor))
    }

    /// Simple-harmonic interpolation between the last two published beats:
    /// the rod is at one extreme exactly on a beat and swings smoothly to
    /// the opposite extreme by the next one, matching real pendulum motion
    /// (fastest through center, momentarily still at each extreme).
    private func currentAngleRadians() -> Double {
        guard viewModel.isPlaying else { return 0 }

        let clock = viewModel.beatClock
        let window = clock.window
        guard let previous = window.previous, let next = window.next else { return 0 }

        let previousSeconds = clock.seconds(fromHostTime: previous.hostTime)
        let nextSeconds = clock.seconds(fromHostTime: next.hostTime)
        let span = nextSeconds - previousSeconds
        guard span > 0 else { return 0 }

        let now = CACurrentMediaTime()
        let progress = ((now - previousSeconds) / span).clamped(to: 0...1)
        let sign: Double = previous.index % 2 == 0 ? 1 : -1
        let maxAngleRadians = maxAngleDegrees * .pi / 180
        return sign * maxAngleRadians * cos(.pi * progress)
    }

    private func weightFraction(forBPM bpm: Double) -> Double {
        let range = MetronomeViewModel.bpmRange
        let t = (range.upperBound - bpm) / (range.upperBound - range.lowerBound)
        return (minFraction + t * (maxFraction - minFraction)).clamped(to: minFraction...maxFraction)
    }

    private func bpm(forFraction fraction: Double) -> Double {
        let range = MetronomeViewModel.bpmRange
        let t = (fraction - minFraction) / (maxFraction - minFraction)
        return range.upperBound - t.clamped(to: 0...1) * (range.upperBound - range.lowerBound)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let dx = value.location.x - pivot.x
                let dy = pivot.y - value.location.y
                let distance = sqrt(dx * dx + dy * dy)
                let fraction = Double(distance / rodLength).clamped(to: minFraction...maxFraction)
                viewModel.bpm = bpm(forFraction: fraction)
            }
    }
}

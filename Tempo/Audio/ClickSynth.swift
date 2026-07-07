import AVFoundation

/// Procedurally synthesizes the metronome's click sounds so the app ships
/// with zero audio assets. Each click is a short sine burst with a fast
/// exponential decay — the same envelope shape used by real mechanical
/// metronomes and drum machine click tracks.
enum ClickSynth {
    private static let duration: Double = 0.04
    // Chosen so the envelope decays to silence well before the buffer ends,
    // avoiding an audible pop at the truncation boundary.
    private static let decayRate: Double = 130.0

    static func makeClickBuffer(format: AVAudioFormat, accent: Bool) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            preconditionFailure("Unable to allocate click buffer")
        }
        buffer.frameLength = frameCount

        let frequency: Double = accent ? 1760 : 1175
        let amplitude: Float = accent ? 0.85 : 0.55

        for channel in 0..<Int(format.channelCount) {
            guard let data = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(frameCount) {
                let t = Double(frame) / sampleRate
                let envelope = exp(-decayRate * t)
                let sample = sin(2.0 * .pi * frequency * t) * envelope
                data[frame] = Float(sample) * amplitude
            }
        }

        return buffer
    }
}

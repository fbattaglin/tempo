import SwiftUI

struct PlayPauseButton: View {
    @ObservedObject var viewModel: MetronomeViewModel

    var body: some View {
        Button {
            viewModel.togglePlayback()
        } label: {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(Circle())
        .help("Play/Pause (Space)")
        // Space is already a global shortcut (see TempoApp's CommandMenu).
        // If this button also held keyboard focus (Full Keyboard Access /
        // VoiceOver), a Space press would fire both the focused control's
        // native activation AND the global shortcut for the same event,
        // double-toggling playback. Keeping it out of focus traversal avoids
        // that without losing mouse or shortcut access.
        .focusable(false)
    }
}

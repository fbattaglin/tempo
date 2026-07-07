import SwiftUI
import AppKit

/// Compact controls shown when Tempo runs from the menu bar, so the
/// metronome can be used without keeping the main window open.
struct MenuBarContentView: View {
    @ObservedObject var viewModel: MetronomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Int(viewModel.bpm.rounded())) BPM")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Spacer()
                TimeSignaturePicker(viewModel: viewModel)
            }

            Slider(
                value: Binding(get: { viewModel.bpm }, set: { viewModel.bpm = $0 }),
                in: MetronomeViewModel.bpmRange,
                step: 1
            )

            HStack {
                Button(viewModel.isPlaying ? "Pausar" : "Tocar") {
                    viewModel.togglePlayback()
                }
                .keyboardShortcut(.space, modifiers: [])

                TapTempoButton(viewModel: viewModel)

                Spacer()

                Button("Sair") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 240)
    }
}

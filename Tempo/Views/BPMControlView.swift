import SwiftUI

struct BPMControlView: View {
    @ObservedObject var viewModel: MetronomeViewModel

    private var isAtDefault: Bool {
        Int(viewModel.bpm.rounded()) == Int(viewModel.defaultBPM.rounded())
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(Int(viewModel.bpm.rounded()))")
                    .font(.system(size: 46, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.bpm)
                Text("BPM")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                if !isAtDefault {
                    Button {
                        viewModel.resetBPMToDefault()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Restaurar \(Int(viewModel.defaultBPM.rounded())) BPM (⌘0)")
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isAtDefault)

            Slider(
                value: Binding(
                    get: { viewModel.bpm },
                    set: { viewModel.bpm = $0 }
                ),
                in: MetronomeViewModel.bpmRange,
                step: 1
            )
            .frame(maxWidth: 240)
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: MetronomeViewModel

    var body: some View {
        Form {
            Section {
                Stepper(
                    value: Binding(
                        get: { viewModel.defaultBPM },
                        set: { viewModel.defaultBPM = $0 }
                    ),
                    in: MetronomeViewModel.bpmRange,
                    step: 1
                ) {
                    HStack {
                        Text("Default BPM")
                        Spacer()
                        Text("\(Int(viewModel.defaultBPM.rounded()))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Use current BPM (\(Int(viewModel.bpm.rounded()))) as default") {
                    viewModel.setCurrentBPMAsDefault()
                }
                .disabled(Int(viewModel.bpm.rounded()) == Int(viewModel.defaultBPM.rounded()))
            } footer: {
                Text("The ↺ button and the ⌘0 shortcut always return to this value.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize()
    }
}

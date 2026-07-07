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
                        Text("BPM padrão")
                        Spacer()
                        Text("\(Int(viewModel.defaultBPM.rounded()))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Usar o BPM atual (\(Int(viewModel.bpm.rounded()))) como padrão") {
                    viewModel.setCurrentBPMAsDefault()
                }
                .disabled(Int(viewModel.bpm.rounded()) == Int(viewModel.defaultBPM.rounded()))
            } footer: {
                Text("O botão ↺ e o atalho ⌘0 sempre voltam para este valor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize()
    }
}

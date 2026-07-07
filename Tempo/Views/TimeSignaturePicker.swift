import SwiftUI

struct TimeSignaturePicker: View {
    @ObservedObject var viewModel: MetronomeViewModel

    var body: some View {
        Picker("Compasso", selection: $viewModel.timeSignature) {
            ForEach(TimeSignature.common) { signature in
                Text(signature.label).tag(signature)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(width: 84)
    }
}

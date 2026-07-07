import SwiftUI

struct TapTempoButton: View {
    @ObservedObject var viewModel: MetronomeViewModel

    var body: some View {
        Button {
            viewModel.registerTap()
        } label: {
            Text("TAP")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 60, height: 30)
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("t", modifiers: [])
        .help("Tap along to set the tempo")
    }
}

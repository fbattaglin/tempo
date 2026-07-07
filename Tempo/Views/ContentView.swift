import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MetronomeViewModel

    var body: some View {
        VStack(spacing: 22) {
            PendulumView(viewModel: viewModel)

            BPMControlView(viewModel: viewModel)

            HStack(spacing: 18) {
                TimeSignaturePicker(viewModel: viewModel)
                PlayPauseButton(viewModel: viewModel)
                TapTempoButton(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
        .padding(.top, 40)
        .background(.background)
        .fixedSize()
    }
}

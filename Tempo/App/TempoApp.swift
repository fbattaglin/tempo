import SwiftUI

@main
struct TempoApp: App {
    @StateObject private var viewModel = MetronomeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandMenu("Metronome") {
                Button(viewModel.isPlaying ? "Pause" : "Play") {
                    viewModel.togglePlayback()
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Increase BPM") {
                    viewModel.nudgeBPM(by: 1)
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button("Decrease BPM") {
                    viewModel.nudgeBPM(by: -1)
                }
                .keyboardShortcut(.downArrow, modifiers: [])

                Button("Increase BPM (+5)") {
                    viewModel.nudgeBPM(by: 5)
                }
                .keyboardShortcut(.upArrow, modifiers: [.shift])

                Button("Decrease BPM (-5)") {
                    viewModel.nudgeBPM(by: -5)
                }
                .keyboardShortcut(.downArrow, modifiers: [.shift])

                Divider()

                Button("Reset to \(Int(viewModel.defaultBPM.rounded())) BPM") {
                    viewModel.resetBPMToDefault()
                }
                .keyboardShortcut("0", modifiers: [.command])
            }
        }

        MenuBarExtra("Tempo", systemImage: "metronome") {
            MenuBarContentView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}

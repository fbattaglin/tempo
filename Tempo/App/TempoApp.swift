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

            CommandMenu("Metrônomo") {
                Button(viewModel.isPlaying ? "Pausar" : "Tocar") {
                    viewModel.togglePlayback()
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Aumentar BPM") {
                    viewModel.nudgeBPM(by: 1)
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button("Diminuir BPM") {
                    viewModel.nudgeBPM(by: -1)
                }
                .keyboardShortcut(.downArrow, modifiers: [])

                Button("Aumentar BPM (+5)") {
                    viewModel.nudgeBPM(by: 5)
                }
                .keyboardShortcut(.upArrow, modifiers: [.shift])

                Button("Diminuir BPM (-5)") {
                    viewModel.nudgeBPM(by: -5)
                }
                .keyboardShortcut(.downArrow, modifiers: [.shift])

                Divider()

                Button("Restaurar \(Int(viewModel.defaultBPM.rounded())) BPM") {
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

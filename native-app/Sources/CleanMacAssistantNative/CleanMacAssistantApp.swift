import SwiftUI

@main
struct CleanMacAssistantNativeApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup(AppBuildFlavor.appName) {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 1220, minHeight: 820)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        #if DEVELOPER_BUILD
        .commands {
            DeveloperCommandMenu(viewModel: viewModel)
        }
        #endif
    }
}

#if DEVELOPER_BUILD
private struct DeveloperCommandMenu: Commands {
    @ObservedObject var viewModel: AppViewModel

    var body: some Commands {
        CommandMenu("Developer") {
            Toggle(isOn: $viewModel.isPlaceboModeEnabled) {
                Text("Placebo Mode")
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            Divider()

            Picker("Interface Language", selection: $viewModel.debugLanguageOverride) {
                ForEach(DebugLanguageOverride.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            Divider()

            Button("Reset Preview State") {
                viewModel.resetDeveloperPreview()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
    }
}
#endif

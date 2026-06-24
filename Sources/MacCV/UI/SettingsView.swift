import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var viewModel: AppState

    var body: some View {
        TabView {
            GeneralSettings(viewModel: viewModel)
                .tabItem { Label("General", systemImage: "gearshape") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 400, height: 300)
        .onAppear {
            NSApp.activate()
        }
    }
}

private struct GeneralSettings: View {
    @Bindable var viewModel: AppState
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("[MacCV] Login item error: \(error)")
                        }
                    }
                    .onAppear {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
            }

            Section("History") {
                HStack {
                    Text("History limit:")
                    Spacer()
                    Text("\(viewModel.maxHistory)")
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                    Stepper("", value: $viewModel.maxHistory, in: 100...5000, step: 100)
                        .labelsHidden()
                        .onChange(of: viewModel.maxHistory) { _, _ in
                            viewModel.refresh()
                        }
                }
            }

        }
        .padding()
    }
}

private struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clipboard")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("MacCV")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Clipboard History Manager")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(spacing: 4) {
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Built with SwiftUI")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

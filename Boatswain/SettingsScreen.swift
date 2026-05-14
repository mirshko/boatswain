//
//  SettingsScreen.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI
import LaunchAtLogin
import Defaults

struct SettingsScreen: View {
    @Default(.fathomApiKey) private var fathomApiKey
    @Default(.activeSite) private var activeSite
    @Default(.refreshRate) private var refreshRate
    @Default(.liveRefreshRate) private var liveRefreshRate

    private let validRefreshRates: Set<TimeInterval> = [60, 300, 600]

    @ObservedObject private var appState = AppState.shared

    var body: some View {
        Form {
            Section {
                SecureField("Fathom API Key", text: $fathomApiKey)
                    .autocorrectionDisabled(true)
                    .onChange(of: fathomApiKey) { _, newValue in
                        if !newValue.isEmpty {
                            Task {
                                await appState.populateSites()
                            }
                        }
                    }

                if appState.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Loading sites...")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                if let error = appState.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Section("Sites") {
                Picker("Active Site", selection: $activeSite) {
                    Text("Select a site").tag("")

                    ForEach(appState.sites) { site in
                        Text(site.name).tag(site.id)
                    }
                }
                .pickerStyle(.menu)
                .disabled(appState.isLoading || appState.sites.isEmpty)
                .onChange(of: activeSite) { _, newValue in
                    guard !newValue.isEmpty else { return }
                    print("[Settings] active site changed to \(newValue)")
                    Task { await appState.refreshActiveSiteData() }
                }

                if appState.sites.isEmpty && !fathomApiKey.isEmpty && !appState.isLoading {
                    Button("Refresh Sites") {
                        Task {
                            await appState.populateSites()
                        }
                    }
                }

                Picker("Dashboard Refresh", selection: $refreshRate) {
                    Text("1 minute").tag(TimeInterval(60))
                    Text("5 minutes").tag(TimeInterval(300))
                    Text("10 minutes").tag(TimeInterval(600))
                }
                .pickerStyle(.menu)
                .onAppear {
                    if !validRefreshRates.contains(refreshRate) {
                        refreshRate = 60
                    }
                }

                Picker("Live Visitors Refresh", selection: $liveRefreshRate) {
                    Text("15 seconds").tag(TimeInterval(15))
                    Text("30 seconds").tag(TimeInterval(30))
                    Text("1 minute").tag(TimeInterval(60))
                    Text("2 minutes").tag(TimeInterval(120))
                    Text("5 minutes").tag(TimeInterval(300))
                }
                .pickerStyle(.menu)
            }

            Section {
                LaunchAtLogin.Toggle()
            }
        }
        .textFieldStyle(.roundedBorder)
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize()
    }
}

#Preview {
    SettingsScreen()
}

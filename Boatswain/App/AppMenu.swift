//
//  AppMenu.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import Defaults
import SwiftUI

struct AppMenu: View {
    @Default(.fathomApiKey) private var apiKey
    @Default(.activeSite) private var activeSiteId

    private var appState = AppState.shared

    var body: some View {
        Group {
            if apiKey.isEmpty, !appState.isDemoMode {
                NoApiKeyView()

                Divider()

                SettingsLink {
                    Text("Settings...")
                }
                .keyboardShortcut(",")
                .unredacted()

                Divider()

                Button("Quit Boatswain") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
                .unredacted()
            } else {
                if !activeSiteId.isEmpty {
                    if let site = appState.sites.first(where: { $0.id == activeSiteId }) {
                        ReportsSectionGroup(site: site)

                        Divider()
                    }
                }

                Text("Sites").font(.subheadline)

                if appState.sites.isEmpty {
                    Text("No sites found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(appState.sites.filter { $0.id != activeSiteId }) { site in
                        Menu(site.name) {
                            ReportsSectionGroup(site: site)
                        }
                    }
                }

                Divider()

                SettingsLink {
                    Text("Settings...")
                }
                .keyboardShortcut(",")
                .unredacted()

                Menu("More") {
                    MoreMenu()
                }
                .unredacted()

                Divider()

                Button("Quit Boatswain") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
                .unredacted()
            }

        }
    }
}

struct NoApiKeyView: View {
    var body: some View {
        SettingsLink {
            Text("Add your Fathom API key in Settings")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

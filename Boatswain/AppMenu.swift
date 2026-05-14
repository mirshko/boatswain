//
//  AppMenu.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI
import Defaults

struct AppMenu: View {
    @Default(.fathomApiKey) private var apiKey
    @Default(.activeSite) private var activeSiteId
    
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        if apiKey.isEmpty {
            NoApiKeyView()
            
            Divider()
            
            SettingsLink {
                Text("Settings...")
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button("Quit Boatswain") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
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
            
            Menu("More") {
                MoreMenu()
            }
            
            Divider()
            
            Button("Quit Boatswain") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}


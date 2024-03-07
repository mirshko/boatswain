//
//  AppMenu.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI
import Defaults

struct AppMenu: View {
    @Default(.activeSite) private var activeSiteId
    
    @EnvironmentObject private var appState: AppState
            
    var body: some View {
        if !activeSiteId.isEmpty {
            if let site = appState.sites.first(where: { $0.id == activeSiteId }) {
                ReportsSectionGroup(site: site)
                            
                Divider()
            }
        }
           
        Text("Sites").font(.subheadline)
                
        ForEach(appState.sites.filter { site in
            if site.id == activeSiteId {
                return false
            } else {
                return true
            }
        }, id:\.id) { site in
            Menu(site.name) {
                ReportsSectionGroup(site: site)
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


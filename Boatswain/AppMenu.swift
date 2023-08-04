//
//  AppMenu.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI

struct AppMenu: View {    
    @EnvironmentObject private var appState: AppState
        
    var body: some View {
        Text("Sites").font(.subheadline)
                
        ForEach(appState.sites, id:\.id) { site in
            Menu(site.name) {
                ReportsSectionGroup(site: site)
            }
        }
        
        Divider()

        Button("Settings...") {
            DispatchQueue.main.async {
                NSApp.sendAction(
                    Selector(("showSettingsWindow:")),
                    to: nil,
                    from: nil
                )
            }
        }
            .keyboardShortcut(",")
        
        Menu("More") {
            MoreMenu()
        }

        Divider()

        Button("Quit Boatswain") {
            NSApplication.shared.terminate(nil)
        }
            .keyboardShortcut("q")
    }
}

struct MoreMenu: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        Button("About") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }
        
        Divider()
        
        Button("Send Feedback...") {
            openURL(URL(string: "https://github.com/mirshko/boatswain/issues/new")!)
        }
    }
}

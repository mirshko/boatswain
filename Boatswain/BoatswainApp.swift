//
//  BoatswainApp.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI

@main
struct BoatswainApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra() {
            AppMenu()
                .environmentObject(appState)
        } label: {
            MenubarIcon()
                .environmentObject(appState)
        }
        
        Settings {
            SettingsScreen()
                .environmentObject(appState)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var sites: [SiteViewModel] = []
    
    static let shared = AppState()
    
    private init() {
        Task {
            await populateSites()
        }
    }
    
    func populateSites() async {
        do {
            let sites = try await Webservice().getSites()
            
            self.sites = sites.map(SiteViewModel.init)
        } catch {
            print(error)
        }
    }
}

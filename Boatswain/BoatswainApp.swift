//
//  BoatswainApp.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI

@main
struct BoatswainApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra() {
            AppMenu()
                .environmentObject(appState)
        } label: {
            Image(systemName: "drop")
        }
        
        Settings {
            SettingsScreen()
                .environmentObject(appState)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var sites: [SiteViewModel] = []
    
    static let shared = AppState()
    
    private init() {
        DispatchQueue.main.async { [self] in
            didLaunch()
        }
    }
    
    private func didLaunch() {
        Task {
            await populateSites()
        }
    }
    
    func populateSites() async {
        do {
            print("populateSites")
            
            let sites = try await Webservice().getSites()
            
            self.sites = sites.map(SiteViewModel.init)
        } catch {
            print(error)
        }
    }
}

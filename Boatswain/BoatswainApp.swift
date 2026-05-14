//
//  BoatswainApp.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import SwiftUI
import Defaults

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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var cachedAggregations: [String: Aggregation] = [:]
    @Published var lastAggregationFetch: [String: Date] = [:]
    @Published var cachedVisitors: [String: Int] = [:]
    @Published var lastVisitorsFetch: [String: Date] = [:]
    
    static let shared = AppState()
    
    private init() {
        Task {
            await populateSites()
        }
    }
    
    func populateSites() async {
        guard !Defaults[.fathomApiKey].isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedSites = try await Webservice.shared.getSites()
            self.sites = fetchedSites.map { SiteViewModel(site: $0) }
        } catch NetworkError.unauthorized {
            errorMessage = "Invalid API key. Please check your Fathom API key in Settings."
        } catch {
            errorMessage = "Failed to load sites: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

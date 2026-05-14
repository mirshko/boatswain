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
            await refreshActiveSiteData()
            refreshBackgroundData()
        } catch NetworkError.unauthorized {
            errorMessage = "Invalid API key. Please check your Fathom API key in Settings."
        } catch {
            errorMessage = "Failed to load sites: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshActiveSiteData() async {
        let activeId = Defaults[.activeSite]
        guard !activeId.isEmpty else { return }
        
        print("[DataTask] active site data: site=\(activeId)")
        
        if let visitors = try? await Webservice.shared.getCurrentVisitors(id: activeId) {
            cachedVisitors[activeId] = visitors
            lastVisitorsFetch[activeId] = Date()
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let last7 = today.addingTimeInterval(-6 * 24 * 60 * 60)
        for (range, dateFrom, dateTo) in [("today", today, Date()), ("last_week", last7, today)] {
            let key = "\(activeId)_\(range)"
            if let result = try? await Webservice.shared.getAggregation(id: activeId, dateTo: dateTo, dateFrom: dateFrom) {
                cachedAggregations[key] = result
                lastAggregationFetch[key] = Date()
            }
        }
    }
    
    func refreshBackgroundData() {
        let activeId = Defaults[.activeSite]
        Task(priority: .low) { @MainActor in
            print("[DataTask] background: starting")
            for site in sites where site.id != activeId {
                let today = Calendar.current.startOfDay(for: Date())
                let last7 = today.addingTimeInterval(-6 * 24 * 60 * 60)
                for (range, dateFrom, dateTo) in [("today", today, Date()), ("last_week", last7, today)] {
                    let key = "\(site.id)_\(range)"
                    guard cachedAggregations[key] == nil else { continue }
                    if let result = try? await Webservice.shared.getAggregation(id: site.id, dateTo: dateTo, dateFrom: dateFrom) {
                        cachedAggregations[key] = result
                        lastAggregationFetch[key] = Date()
                    }
                }
            }
            print("[DataTask] background: complete")
        }
    }
    
    func refreshSubmenuData(for siteId: String) async {
        print("[DataTask] submenu refresh: site=\(siteId)")
        let today = Calendar.current.startOfDay(for: Date())
        let last7 = today.addingTimeInterval(-6 * 24 * 60 * 60)
        for (range, dateFrom, dateTo) in [("today", today, Date()), ("last_week", last7, today)] {
            let key = "\(siteId)_\(range)"
            lastAggregationFetch.removeValue(forKey: key)
            if let result = try? await Webservice.shared.getAggregation(id: siteId, dateTo: dateTo, dateFrom: dateFrom) {
                cachedAggregations[key] = result
                lastAggregationFetch[key] = Date()
            }
        }
    }
}

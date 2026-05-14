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
    var body: some Scene {
        MenuBarExtra() {
            AppMenu()
        } label: {
            MenubarIcon()
        }
        
        Settings {
            SettingsScreen()
        }
    }
}

@MainActor
@Observable
final class AppState {
    var sites: [SiteViewModel] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var cachedAggregations: [String: Aggregation] = [:]
    var lastAggregationFetch: [String: Date] = [:]
    var cachedVisitors: [String: Int] = [:]
    var lastVisitorsFetch: [String: Date] = [:]
    
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
        
        do {
            let visitors = try await Webservice.shared.getCurrentVisitors(id: activeId)
            cachedVisitors[activeId] = visitors
            lastVisitorsFetch[activeId] = Date()
        } catch {
            print("Error fetching visitors: \(error)")
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let last7 = today.addingTimeInterval(-6 * 24 * 60 * 60)
        for (range, dateFrom, dateTo) in [("today", today, Date()), ("last_week", last7, today)] {
            let key = "\(activeId)_\(range)"
            do {
                let result = try await Webservice.shared.getAggregation(id: activeId, dateTo: dateTo, dateFrom: dateFrom)
                cachedAggregations[key] = result
                lastAggregationFetch[key] = Date()
            } catch {
                print("Error fetching aggregation: \(error)")
            }
        }
    }
    
    func refreshBackgroundData() {
        let activeId = Defaults[.activeSite]
        Task(priority: .low) { @MainActor in
            for site in sites where site.id != activeId {
                if cachedVisitors[site.id] == nil {
                    do {
                        let visitors = try await Webservice.shared.getCurrentVisitors(id: site.id)
                        cachedVisitors[site.id] = visitors
                    } catch {
                        print("Error fetching visitors: \(error)")
                    }
                }
                let today = Calendar.current.startOfDay(for: Date())
                let last7 = today.addingTimeInterval(-6 * 24 * 60 * 60)
                for (range, dateFrom, dateTo) in [("today", today, Date()), ("last_week", last7, today)] {
                    let key = "\(site.id)_\(range)"
                    guard cachedAggregations[key] == nil else { continue }
                    do {
                        let result = try await Webservice.shared.getAggregation(id: site.id, dateTo: dateTo, dateFrom: dateFrom)
                        cachedAggregations[key] = result
                        lastAggregationFetch[key] = Date()
                    } catch {
                        print("Error fetching aggregation: \(error)")
                    }
                }
            }
        }
    }
    
    func refreshSubmenuData(for siteId: String) async {
        do {
            let visitors = try await Webservice.shared.getCurrentVisitors(id: siteId)
            cachedVisitors[siteId] = visitors
        } catch {
            print("Error fetching visitors: \(error)")
        }
        let today = Calendar.current.startOfDay(for: Date())
        let last7 = today.addingTimeInterval(-6 * 24 * 60 * 60)
        for (range, dateFrom, dateTo) in [("today", today, Date()), ("last_week", last7, today)] {
            let key = "\(siteId)_\(range)"
            lastAggregationFetch.removeValue(forKey: key)
            do {
                let result = try await Webservice.shared.getAggregation(id: siteId, dateTo: dateTo, dateFrom: dateFrom)
                cachedAggregations[key] = result
                lastAggregationFetch[key] = Date()
            } catch {
                print("Error fetching aggregation: \(error)")
            }
        }
    }
}

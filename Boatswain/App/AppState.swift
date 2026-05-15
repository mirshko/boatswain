//
//  AppState.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.08.23.
//

import Defaults
import Foundation

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

    private let webservice = Webservice.shared

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
            let fetchedSites = try await webservice.getSites()
            sites = fetchedSites.map { SiteViewModel(site: $0) }
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

        await fetchVisitors(for: activeId)
        await fetchAggregations(for: activeId)
    }

    func refreshBackgroundData() {
        let activeId = Defaults[.activeSite]
        Task(priority: .low) { @MainActor in
            for site in sites where site.id != activeId {
                if cachedVisitors[site.id] == nil {
                    await fetchVisitors(for: site.id)
                }
                await fetchAggregations(for: site.id)
            }
        }
    }

    func refreshSubmenuData(for siteId: String) async {
        await fetchVisitors(for: siteId)
        lastAggregationFetch.keys.filter { $0.hasPrefix("\(siteId)_") }.forEach {
            lastAggregationFetch.removeValue(forKey: $0)
        }
        await fetchAggregations(for: siteId)
    }

    private func fetchVisitors(for siteId: String) async {
        do {
            let visitors = try await webservice.getCurrentVisitors(id: siteId)
            cachedVisitors[siteId] = visitors
            lastVisitorsFetch[siteId] = Date()
        } catch {}
    }

    private func fetchAggregations(for siteId: String) async {
        let today = Calendar.current.startOfDay(for: Date())
        let last7 = today.addingTimeInterval(-6 * 24 * 60 * 60)
        for (range, dateFrom, dateTo) in [("today", today, Date()), ("last_week", last7, today)] {
            let key = "\(siteId)_\(range)"
            do {
                let result = try await webservice.getAggregation(id: siteId, dateTo: dateTo, dateFrom: dateFrom)
                cachedAggregations[key] = result
                lastAggregationFetch[key] = Date()
            } catch {}
        }
    }
}

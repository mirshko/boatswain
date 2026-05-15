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

    private(set) var isDemoMode = false
    var showDemoModeToggle = false

    static let shared = AppState()

    private let webservice = Webservice.shared

    private init() {
        Task {
            await populateSites()
        }

        Task {
            await backgroundRefreshLoop()
        }
    }

    func enableDemoMode() {
        guard !isDemoMode else { return }

        isDemoMode = true
        sites = [
            SiteViewModel(site: Site(id: "demo-1", name: "example.com", sharing: "none", createdAt: "")),
            SiteViewModel(site: Site(id: "demo-2", name: "wikipedia.org", sharing: "none", createdAt: "")),
            SiteViewModel(site: Site(id: "demo-3", name: "eff.org", sharing: "none", createdAt: ""))
        ]
        Defaults[.activeSite] = "demo-1"

        for site in sites {
            cachedVisitors[site.id] = Int.random(in: 1...50)
            cachedAggregations["\(site.id)_today"] = Aggregation(
                visits: "\(Int.random(in: 100...5000))",
                uniques: "\(Int.random(in: 50...2500))",
                pageviews: "\(Int.random(in: 200...10000))",
                avgDuration: String(format: "%.1f", Double.random(in: 30...300)),
                bounceRate: String(format: "%.1f", Double.random(in: 20...80))
            )
            cachedAggregations["\(site.id)_last_week"] = Aggregation(
                visits: "\(Int.random(in: 500...50000))",
                uniques: "\(Int.random(in: 200...25000))",
                pageviews: "\(Int.random(in: 1000...100000))",
                avgDuration: String(format: "%.1f", Double.random(in: 30...300)),
                bounceRate: String(format: "%.1f", Double.random(in: 20...80))
            )
        }
    }

    func disableDemoMode() {
        isDemoMode = false
        sites = []
        cachedAggregations = [:]
        cachedVisitors = [:]
        Defaults[.activeSite] = ""
    }

    func resetDemoFlags() {
        isDemoMode = false
        showDemoModeToggle = false
    }

    private func backgroundRefreshLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(max(Defaults[.refreshRate], 60) * 1_000_000_000))
            refreshBackgroundData()
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
                await fetchVisitors(for: site.id)
                await fetchAggregations(for: site.id)
            }
        }
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

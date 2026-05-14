//
//  Stats.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import SwiftUI
import Defaults

struct ReportsSection: View {
    let site: SiteViewModel
    let range: String
    let dateTo: Date
    let dateFrom: Date

    @Default(.activeSite) private var activeSiteId
    @Default(.refreshRate) private var refreshRate

    @State private var aggr: Aggregation?
    @State private var isLoading = true

    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL

    private var isActive: Bool { site.id == activeSiteId }

    private func cacheKey(_ id: String) -> String {
        "\(id)_\(range.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    private func formatDuration(_ seconds: String?) -> String {
        guard let secsStr = seconds, let total = Double(secsStr), total > 0 else { return "-" }
        let secs = Int(total)
        if secs < 60 {
            return "\(secs)s"
        }
        let minutes = secs / 60
        let remainingSeconds = secs % 60
        return "\(minutes)m \(remainingSeconds)s"
    }

    private func formatNumber(_ value: String?) -> String {
        guard let str = value, let num = Int(str) else { return "-" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: num)) ?? "-"
    }
    
    private func formatPercent(_ value: String?) -> String {
        guard let str = value, let num = Double(str) else { return "-" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = .current
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: num / 100)) ?? "-"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(range)

            if isLoading {
                Text("Loading...")
                    .foregroundColor(.secondary)
            } else {
                Text("\(formatNumber(aggr?.visits)) sessions")
                Text("\(formatNumber(aggr?.uniques)) uniques")
                Text("\(formatNumber(aggr?.pageviews)) views")
                Text("\(formatPercent(aggr?.bounceRate)) bounce rate")
                Text("\(formatDuration(aggr?.avgDuration)) avg time on site")
            }

            Button("View Dashboard") {
                let rangeParam = range == "Today" ? "today" : "last_7_days"
                openURL(URL(string: "\(Constants.URLs.fathomDashboard)?comparison=none&range=\(rangeParam)&site=\(site.id)")!)
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
        }
        .task {
            await fetchAggregation()
        }
    }
    
    private func fetchAggregation() async {
        let key = cacheKey(site.id)

        if isActive, refreshRate > 0 {
            if let lastFetch = appState.lastAggregationFetch[key],
               Date().timeIntervalSince(lastFetch) < refreshRate,
               let cached = appState.cachedAggregations[key] {
                aggr = cached
                isLoading = false
                return
            }
        }

        isLoading = true
        do {
            let result = try await Webservice.shared.getAggregation(id: site.id, dateTo: dateTo, dateFrom: dateFrom)
            appState.cachedAggregations[key] = result
            appState.lastAggregationFetch[key] = Date()
            self.aggr = result
        } catch {
            if error is CancellationError { isLoading = false; return }
            if let urlError = error as? URLError, urlError.code == .cancelled { isLoading = false; return }
            print("Error fetching aggregation: \(error)")
        }
        isLoading = false
    }
}

struct ReportsSectionGroup: View {
    let site: SiteViewModel

    @Default(.activeSite) private var activeSiteId

    @EnvironmentObject private var appState: AppState

    private var isActive: Bool { site.id == activeSiteId }

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var dateFromLast7: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(-6 * 24 * 60 * 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(site.name)

            if isActive {
                Text("Live")
                    .foregroundColor(.secondary)

                Text("\(appState.cachedVisitors[site.id] ?? 0) visitors")

                Divider()
                    .padding(.vertical, 3)
            }

            ReportsSection(site: site, range: "Today", dateTo: Date(), dateFrom: startOfToday)

            Divider()
                .padding(.vertical, 3)

            ReportsSection(site: site, range: "Last Week", dateTo: startOfToday, dateFrom: dateFromLast7)
        }
        .padding(6)
        .frame(minWidth: 220)
    }
}

struct LazyReportsSectionGroup: View {
    let site: SiteViewModel

    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                ReportsSectionGroup(site: site)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(site.name)
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
                .padding(6)
                .frame(minWidth: 180)
            }
        }
        .onAppear {
            isLoaded = true
        }
    }
}

struct NoApiKeyView: View {
    var body: some View {
        SettingsLink {
            Text("Add your Fathom API key in Settings")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
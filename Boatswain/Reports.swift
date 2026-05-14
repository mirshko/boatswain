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

    @ObservedObject private var appState = AppState.shared
    @Environment(\.openURL) private var openURL

    private var isActive: Bool { site.id == activeSiteId }

    private var cacheKey: String {
        "\(site.id)_\(range.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    private var aggr: Aggregation? {
        appState.cachedAggregations[cacheKey]
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

    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(range)

            Text("\(formatNumber(aggr?.visits)) sessions")
            Text("\(formatNumber(aggr?.uniques)) uniques")
            Text("\(formatNumber(aggr?.pageviews)) views")
            Text("\(formatPercent(aggr?.bounceRate)) bounce rate")
            Text("\(formatDuration(aggr?.avgDuration)) avg time on site")

            Button("View Dashboard") {
                let rangeParam = range == "Today" ? "today" : "last_7_days"
                openURL(URL(string: "\(Constants.URLs.fathomDashboard)?comparison=none&range=\(rangeParam)&site=\(site.id)")!)
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            .unredacted()
        }
        .redacted(reason: aggr == nil ? .placeholder : [])
        .overlay {
            if isLoading && aggr == nil {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .task {
            guard isActive else { return }
            await fetchAggregation()
            isLoading = false
            let interval = UInt64(max(refreshRate, 60) * 1_000_000_000)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                await fetchAggregation()
            }
        }
    }
    
    private func fetchAggregation() async {
        let key = cacheKey

        if refreshRate > 0 {
            if let lastFetch = appState.lastAggregationFetch[key],
               Date().timeIntervalSince(lastFetch) < refreshRate,
               appState.cachedAggregations[key] != nil {
                return
            }
        }

        do {
            let result = try await Webservice.shared.getAggregation(id: site.id, dateTo: dateTo, dateFrom: dateFrom)
            appState.cachedAggregations[key] = result
            appState.lastAggregationFetch[key] = Date()
        } catch {
            if error is CancellationError { return }
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
        }
    }
}

struct ReportsSectionGroup: View {
    let site: SiteViewModel

    @Default(.activeSite) private var activeSiteId

    @ObservedObject private var appState = AppState.shared

    private var isActive: Bool { site.id == activeSiteId }

    private var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var dateFromLast7: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(-6 * 24 * 60 * 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Live")
                .foregroundColor(.secondary)
            Text("\(appState.cachedVisitors[site.id] ?? 0) visitors")
                .redacted(reason: appState.cachedVisitors[site.id] == nil ? .placeholder : [])
            Divider()
                .padding(.vertical, 3)

            ReportsSection(site: site, range: "Today", dateTo: Date(), dateFrom: startOfToday)

            Divider()
                .padding(.vertical, 3)

            ReportsSection(site: site, range: "Last Week", dateTo: startOfToday, dateFrom: dateFromLast7)
        }
        .padding(6)
        .frame(minWidth: 220)
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
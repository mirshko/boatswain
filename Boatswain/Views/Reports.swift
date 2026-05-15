//
//  Reports.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import Defaults
import SwiftUI

struct ReportsSection: View {
    let site: SiteViewModel
    let range: String
    let dateTo: Date
    let dateFrom: Date

    @Default(.activeSite) private var activeSiteId
    @Default(.refreshRate) private var refreshRate

    private var appState = AppState.shared

    @Environment(\.openURL) private var openURL

    init(site: SiteViewModel, range: String, dateTo: Date, dateFrom: Date) {
        self.site = site
        self.range = range
        self.dateTo = dateTo
        self.dateFrom = dateFrom
    }

    private var isActive: Bool {
        site.id == activeSiteId
    }

    private var cacheKey: String {
        "\(site.id)_\(range.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    private var aggr: Aggregation? {
        appState.cachedAggregations[cacheKey]
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
                let url = "\(Constants.URLs.fathomDashboard)?comparison=none&range=\(rangeParam)&site=\(site.id)"
                openURL(URL(string: url)!)
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            .unredacted()
        }
        .redacted(reason: aggr == nil ? .placeholder : [])
        .overlay {
            if isLoading, aggr == nil {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .task {
            if isActive {
                await fetchAggregation()
                isLoading = false
                let interval = UInt64(max(refreshRate, 60) * 1_000_000_000)
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: interval)
                    await fetchAggregation()
                }
            } else {
                isLoading = false
            }
        }
    }

    private func fetchAggregation() async {
        let key = cacheKey

        if refreshRate > 0 {
            if let lastFetch = appState.lastAggregationFetch[key],
               Date().timeIntervalSince(lastFetch) < refreshRate,
               appState.cachedAggregations[key] != nil { return }
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

    private var appState = AppState.shared

    init(site: SiteViewModel) {
        self.site = site
    }

    private var isActive: Bool {
        site.id == activeSiteId
    }

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

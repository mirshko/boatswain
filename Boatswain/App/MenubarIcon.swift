//
//  MenubarIcon.swift
//  Boatswain
//
//  Created by Jeff Reiner on 03.02.24.
//

import Defaults
import SwiftUI

struct MenubarIcon: View {
    @Default(.fathomApiKey) private var apiKey
    @Default(.activeSite) private var activeSiteId
    @Default(.liveRefreshRate) private var liveRefreshRate

    private var appState = AppState.shared

    private var liveVisitors: Int? {
        appState.cachedVisitors[activeSiteId]
    }

    private func refreshVisitors() async {
        guard !activeSiteId.isEmpty else { return }
        do {
            let result = try await Webservice.shared.getCurrentVisitors(id: activeSiteId)
            appState.cachedVisitors[activeSiteId] = result
            appState.lastVisitorsFetch[activeSiteId] = Date()
        } catch {
            if error is CancellationError { return }
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
        }
    }

    var body: some View {
        Group {
            if apiKey.isEmpty, !appState.isDemoMode {
                Image(systemName: "sailboat")
            } else if activeSiteId.isEmpty {
                Image(systemName: "sailboat.fill")
            } else if let visitors = liveVisitors {
                Text("\(visitors) visitor\(visitors == 1 ? "" : "s")")
            } else {
                Image(systemName: "sailboat.fill")
            }
        }
        .task(id: activeSiteId) {
            guard !activeSiteId.isEmpty else { return }
            await refreshVisitors()
            let interval = UInt64(max(liveRefreshRate, 15) * 1_000_000_000)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                await refreshVisitors()
            }
        }
    }
}

//
//  Constants.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import Foundation
import Defaults

enum Constants {
    enum URLs {
        static let sites = URL(string: "https://api.usefathom.com/v1/sites")!
        static let currentVisitors = URL(string: "https://api.usefathom.com/v1/current_visitors")!
        static let aggregations = URL(string: "https://api.usefathom.com/v1/aggregations")!
        static let fathomDashboard = "https://app.usefathom.com/"
    }
}

extension Defaults.Keys {
    static let fathomApiKey = Key<String>("fathomApiKey", default: "")
    static let activeSite = Key<String>("activeSite", default: "")
    static let refreshRate = Key<TimeInterval>("refreshRate", default: 60)
    static let liveRefreshRate = Key<TimeInterval>("liveRefreshRate", default: 60)
}

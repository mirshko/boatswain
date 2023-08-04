//
//  Constants.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import Foundation
import Defaults

struct Constants {
    struct URLs {
        static let sites = URL(string: "https://api.usefathom.com/v1/sites")!
        
        static let currentVisitors = URL(string: "https://api.usefathom.com/v1/current_visitors")!
    }
}

extension Defaults.Keys {
    static let fathomApiKey = Key<String>("fathomApiKey", default: "")
}

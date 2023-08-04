//
//  Models.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import Foundation

struct Site: Decodable {
    let id: String
    let name: String
    let sharing: String
    let created_at: String
}

struct SiteViewModel {
    private var site: Site
    
    init(site: Site) {
        self.site = site
    }
    
    var name: String {
        site.name
    }
    
    var id: String {
        site.id
    }
}

struct Event: Decodable {
    let id: String
    let object: String
    let name: String
    let site_id: String
    let created_at: String
}

struct Aggregation: Decodable {
    let visits: String
    let uniques: String
    let pageviews: String
    let avg_duration: String
    let bounce_rate: Double
}

struct AggregationViewModel {
    private var aggr: Aggregation
    
    init(aggr: Aggregation) {
        self.aggr = aggr
    }
    
    var visits: String {
        aggr.visits
    }
    
    var uniques: String {
        aggr.uniques
    }

    var pageviews: String {
        aggr.pageviews
    }
    
    var avg_duration: String {
        aggr.avg_duration
    }
    
    var bounce_rate: Double {
        aggr.bounce_rate
    }
}

//
//  Models.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import Foundation

struct Site: Codable, Identifiable {
    let id: String
    let name: String
    let sharing: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sharing
        case createdAt = "created_at"
    }
}

struct SiteViewModel: Identifiable {
    let site: Site

    var id: String {
        site.id
    }

    var name: String {
        site.name
    }
}

struct Event: Codable, Identifiable {
    let id: String
    let object: String
    let name: String
    let siteId: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case name
        case siteId = "site_id"
        case createdAt = "created_at"
    }
}

struct Aggregation: Codable {
    let visits: String?
    let uniques: String?
    let pageviews: String?
    let avgDuration: String?
    let bounceRate: String?

    enum CodingKeys: String, CodingKey {
        case visits
        case uniques
        case pageviews
        case avgDuration = "avg_duration"
        case bounceRate = "bounce_rate"
    }
}

struct CurrentVisitorsResponse: Codable {
    let total: Int
    var content: [PageviewContent]?
    var referrers: [ReferrerContent]?
}

struct PageviewContent: Codable {
    let pathname: String
    let hostname: String
    let total: Int
}

struct ReferrerContent: Codable {
    let referrerHostname: String
    let referrerPathname: String
    let total: Int

    enum CodingKeys: String, CodingKey {
        case referrerHostname = "referrer_hostname"
        case referrerPathname = "referrer_pathname"
        case total
    }
}

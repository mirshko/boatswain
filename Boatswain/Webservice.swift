//
//  Webservice.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import Foundation
import Defaults

enum NetworkError: Error {
    case invalidResponse
    case invalidURL
}

struct SitesApiResponse: Decodable {
    let object: String
    let url: String
    let has_more: Bool
    var data: [Site]
}

struct EventsApiResponse: Decodable {
    let object: String
    let url: String
    let has_more: Bool
    var data: [Event]
}

struct CurrentVisitorsApiResponse: Decodable {
    let total: String
}

class Webservice {
    private var apiKey = Defaults[.fathomApiKey]
    
    func getSites() async throws -> [Site] {
        print("getSites")

        var request = URLRequest(url: Constants.URLs.sites)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(SitesApiResponse.self, from: data).data
    }
    
    func getCurrentVisiors(id: String) async throws -> String {
        print("getCurrentVisiors \(id)")
        
        let siteId = URLQueryItem(name: "site_id", value: id)
        
        var request = URLRequest(url: Constants.URLs.currentVisitors.appending(queryItems: [siteId]))
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(CurrentVisitorsApiResponse.self, from: data).total
    }
    
    func getEvents(id: String) async throws -> [Event] {
        print("getEvents \(id)")
                    
        var request = URLRequest(url: URL(string: "https://api.usefathom.com/v1/sites/\(id)/events")!)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(EventsApiResponse.self, from: data).data
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func getAggregation(id: String) async throws -> Aggregation {
        print("getAggregation \(id)")

        let today = Date()
        let calendar = Calendar.current

        // Set date_to as today's date
        let date_to = calendar.startOfDay(for: today)

        // Subtract 6 days from date_to to get date_from
        var components = DateComponents()
        components.day = -6
        let date_from = calendar.date(byAdding: components, to: date_to)!
        
        var urlComponents = URLComponents(string: "https://api.usefathom.com/v1/aggregations")

        urlComponents?.queryItems = [
            URLQueryItem(name: "entity", value: "pageview"),
            URLQueryItem(name: "entity_id", value: id),
            URLQueryItem(name: "aggregates", value: "visits,uniques,pageviews,avg_duration,bounce_rate"),
            URLQueryItem(name: "date_from", value: dateFormatter.string(from: date_from)),
            URLQueryItem(name: "date_to", value: dateFormatter.string(from: date_to))
        ]
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
                            
        var request = URLRequest(url: url)
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let decoded = try JSONDecoder().decode([Aggregation].self, from: data)
        
        let result: Aggregation?
        
        if let first = decoded.first {
            result = first
        } else {
            throw NetworkError.invalidResponse
        }
        
        return result!
    }
    
}

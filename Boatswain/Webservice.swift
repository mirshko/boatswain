//
//  Webservice.swift
//  Boatswain
//
//  Created by Jeff Reiner on 04.08.23.
//

import Foundation
import Defaults

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case invalidURL
    case unauthorized
    case rateLimited(TimeInterval?)
    case serverError(Int, String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Invalid API key"
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limited by Fathom API (retry after \(Int(retryAfter))s)"
            }
            return "Rate limited by Fathom API"
        case .serverError(let code, let body): return "Server error (HTTP \(code): \(body))"
        case .decodingFailed(let error): return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}

struct SitesApiResponse: Codable {
    let object: String
    let url: String
    let hasMore: Bool
    var data: [Site]

    enum CodingKeys: String, CodingKey {
        case object, url
        case hasMore = "has_more"
        case data
    }
}

struct ErrorResponse: Codable {
    let error: String
}

actor RateLimiter {
    private var window: [(Date, String)] = []
    private let maxRequests: Int
    private let windowSeconds: TimeInterval
    private let label: String

    init(maxRequests: Int, perSeconds: TimeInterval, label: String = "") {
        self.maxRequests = maxRequests
        self.windowSeconds = perSeconds
        self.label = label
    }

    func waitIfNeeded() async {
        let now = Date()
        window.removeAll { now.timeIntervalSince($0.0) > windowSeconds }

        guard window.count >= maxRequests else {
            window.append((now, ""))
            return
        }

        if let oldest = window.first {
            let wait = windowSeconds - now.timeIntervalSince(oldest.0) + 0.5
            if wait > 0 {
                print("[RateLimiter] waiting \(String(format: "%.1f", wait))s (\(label): \(maxRequests)/\(Int(windowSeconds))s)")
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }

        window.removeFirst()
        window.append((Date(), ""))
    }
}

final class Webservice: @unchecked Sendable {
    static let shared = Webservice()

    private let decoder: JSONDecoder
    private let dateFormatter: DateFormatter
    private let session: URLSession

    private let aggregationLimiter = RateLimiter(maxRequests: 9, perSeconds: 60, label: "aggregations")
    private let siteLimiter = RateLimiter(maxRequests: 1900, perSeconds: 3600, label: "sites")

    private init() {
        self.decoder = JSONDecoder()

        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

private func prettyPrint(_ data: Data) -> String {
        if let obj = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return String(data: data, encoding: .utf8) ?? "nil"
    }

    private func apiKey() -> String {
        UserDefaults.standard.string(forKey: "fathomApiKey") ?? ""
    }

    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func handleResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        let body = String(data: data, encoding: .utf8) ?? "unknown"
        let errorMessage = (try? decoder.decode(ErrorResponse.self, from: data))?.error ?? body

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { TimeInterval($0) }
            print("[API] rate limited\(retryAfter.map { " (retry after \(Int($0))s)" } ?? "")")
            throw NetworkError.rateLimited(retryAfter)
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        default:
            print("[API] HTTP \(httpResponse.statusCode): \(body)")
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        }
    }

    private func retry<T: Sendable>(
        maxAttempts: Int = 3,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            try Task.checkCancellation()

            do {
                return try await operation()
            } catch {
                lastError = error

                switch error {
                case NetworkError.rateLimited(let retryAfter):
                    let delay = retryAfter ?? pow(2.0, Double(attempt)) + Double.random(in: 0...1)
                    print("[API] retry \(attempt + 1)/\(maxAttempts) in \(String(format: "%.1f", delay))s: \(error.localizedDescription)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                case NetworkError.serverError:
                    let delay = pow(2.0, Double(attempt)) + Double.random(in: 0...1)
                    print("[API] retry \(attempt + 1)/\(maxAttempts) in \(String(format: "%.1f", delay))s: \(error.localizedDescription)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                default:
                    throw error
                }
            }
        }

        throw lastError ?? NetworkError.invalidResponse
    }

    func getSites() async throws -> [Site] {
        await siteLimiter.waitIfNeeded()

        let request = createRequest(url: Constants.URLs.sites)

        let (data, response) = try await session.data(for: request)
        try handleResponse(response, data: data)

        print("[API] GET /v1/sites:\n\(prettyPrint(data))")

        let decoded = try decoder.decode(SitesApiResponse.self, from: data)
        return decoded.data
    }

    func getCurrentVisitors(id: String) async throws -> Int {
        await aggregationLimiter.waitIfNeeded()

        let url = Constants.URLs.currentVisitors.appending(queryItems: [URLQueryItem(name: "site_id", value: id)])
        let request = createRequest(url: url)

        let (data, response) = try await session.data(for: request)
        try handleResponse(response, data: data)

        print("[API] GET /v1/current_visitors?site_id=\(id):\n\(prettyPrint(data))")

        let result = try decoder.decode(CurrentVisitorsResponse.self, from: data)
        return result.total
    }

    func getAggregation(id: String, dateTo: Date, dateFrom: Date) async throws -> Aggregation {
        await aggregationLimiter.waitIfNeeded()

        guard var urlComponents = URLComponents(url: Constants.URLs.aggregations, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "entity", value: "pageview"),
            URLQueryItem(name: "entity_id", value: id),
            URLQueryItem(name: "aggregates", value: "visits,uniques,pageviews,avg_duration,bounce_rate"),
            URLQueryItem(name: "date_from", value: dateFormatter.string(from: dateFrom)),
            URLQueryItem(name: "date_to", value: dateFormatter.string(from: dateTo))
        ]

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        return try await retry {
            let request = self.createRequest(url: url)

            let (data, response) = try await self.session.data(for: request)
            try self.handleResponse(response, data: data)

            print("[API] GET /v1/aggregations entity=pageview entity_id=\(id):\n\(self.prettyPrint(data))")

            let decoded = try self.decoder.decode([Aggregation].self, from: data)

            guard let first = decoded.first else {
                return Aggregation(visits: nil, uniques: nil, pageviews: nil, avgDuration: nil, bounceRate: nil)
            }

            return first
        }
    }
}
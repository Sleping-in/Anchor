//
//  ThroughLineAPIClient.swift
//  Anchor
//
//  ThroughLine API integration for global helpline data.
//

import Foundation

struct ThroughLineAPIConfig {
    let baseURL: URL
    let token: String

    static func fromInfoPlist() -> ThroughLineAPIConfig? {
        guard
            let baseURLString = Bundle.main.object(forInfoDictionaryKey: "THROUGHLINE_API_BASE_URL") as? String,
            let token = Bundle.main.object(forInfoDictionaryKey: "THROUGHLINE_API_TOKEN") as? String,
            !baseURLString.isEmpty,
            !token.isEmpty,
            let baseURL = URL(string: baseURLString)
        else {
            return nil
        }
        return ThroughLineAPIConfig(baseURL: baseURL, token: token)
    }
}

enum ThroughLineAPIError: Error {
    case missingConfig
    case invalidURL
    case invalidResponse
}

final class ThroughLineAPIClient {
    static let shared = ThroughLineAPIClient()
    private init() {}

    func fetchHelplines(countryCode: String, limit: Int = 10, priorityOnly: Bool = true) async throws -> [ThroughLineHelpline] {
        guard let config = ThroughLineAPIConfig.fromInfoPlist() else {
            throw ThroughLineAPIError.missingConfig
        }

        var components = URLComponents(url: config.baseURL.appendingPathComponent("helplines"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "country_code", value: countryCode.lowercased()),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "priority_only", value: String(priorityOnly))
        ]

        guard let url = components?.url else {
            throw ThroughLineAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ThroughLineAPIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ThroughLineHelplinesResponse.self, from: data)
        return decoded.helplines
    }
}

struct ThroughLineHelplinesResponse: Decodable {
    let helplines: [ThroughLineHelpline]
}

struct ThroughLineHelpline: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let website: String?
    let phoneNumber: String?
    let smsNumber: String?
    let webChatUrl: String?
    let whatsappUrl: String?
}

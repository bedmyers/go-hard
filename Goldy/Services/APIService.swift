//
//  APIService.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://go-hard-backend-production.up.railway.app"
    
    private init() {}
    
    private func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
    
    // MARK: - Generic Request Method
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("Invalid URL: \(baseURL)\(endpoint)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Using auth token: \(token.prefix(20))...")
        } else {
            print("No auth token found")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("Request body: \(body)")
        }
        
        print("📡 [\(method)] \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("Status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString.prefix(500))")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorDict["error"] as? String {
                print("Server error: \(errorMessage)")
                
                if httpResponse.statusCode == 401 {
                    NotificationCenter.default.post(name: .userUnauthorized, object: nil)
                    throw APIError.unauthorized
                }
                
                throw APIError.serverError(errorMessage)
            }
            
            if httpResponse.statusCode == 401 {
                NotificationCenter.default.post(name: .userUnauthorized, object: nil)
                throw APIError.unauthorized
            }
            
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let decoded = try decoder.decode(T.self, from: data)
            print("Successfully decoded response")
            return decoded
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    private func makeRequestNoResponse(
        endpoint: String,
        method: String = "DELETE",
        body: [String: Any]? = nil
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        print("[\(method)] \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("Status: \(httpResponse.statusCode)")
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorDict["error"] as? String {
                throw APIError.serverError(errorMessage)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        print("Request successful")
    }
    
    // MARK: - Stripe Connect Methods
    
    func getConnectStatus() async throws -> ConnectStatus {
        return try await makeRequest(endpoint: "/stripe/connect/status")
    }
    
    func startOnboarding() async throws -> OnboardResponse {
        return try await makeRequest(endpoint: "/stripe/connect/onboard", method: "POST")
    }
    
    func getDashboardLink() async throws -> OnboardResponse {
        return try await makeRequest(endpoint: "/stripe/connect/dashboard")
    }
    
    // MARK: - Projects Methods
    
    func getProjects() async throws -> ProjectsResponse {
        return try await makeRequest(endpoint: "/projects")
    }
    
    func getProject(_ projectId: Int) async throws -> Project {
        return try await makeRequest(endpoint: "/projects/\(projectId)")
    }
    
    func createProject(body: [String: Any]) async throws -> Project {
        return try await makeRequest(endpoint: "/projects", method: "POST", body: body)
    }
    
    func deleteProject(_ projectId: Int) async throws {
        try await makeRequestNoResponse(endpoint: "/projects/\(projectId)", method: "DELETE")
    }
    
    // MARK: - Vendor Methods
    
    func addVendorToProject(projectId: Int, body: [String: Any]) async throws -> ProjectVendorResponse {
        return try await makeRequest(endpoint: "/projects/\(projectId)/vendors", method: "POST", body: body)
    }
    
    func updateProjectVendor(projectId: Int, vendorId: Int, body: [String: Any]) async throws -> ProjectVendorResponse {
        return try await makeRequest(endpoint: "/projects/\(projectId)/vendors/\(vendorId)", method: "PATCH", body: body)
    }

    func removeVendorFromProject(projectId: Int, vendorId: Int) async throws -> GenericSuccessResponse {
        return try await makeRequest(endpoint: "/projects/\(projectId)/vendors/\(vendorId)", method: "DELETE")
    }

    // MARK: - Agreement Acceptance

    func acceptAgreement(projectVendorId: Int) async throws -> AcceptAgreementResponse {
        return try await makeRequest(endpoint: "/project-vendors/\(projectVendorId)/accept", method: "POST")
    }

    func declineAgreement(projectVendorId: Int) async throws -> AcceptAgreementResponse {
        return try await makeRequest(endpoint: "/project-vendors/\(projectVendorId)/decline", method: "POST")
    }

    // MARK: - Escrow Methods
    
    func createEscrow(projectVendorId: Int, body: [String: Any]) async throws -> EscrowResponse {
        return try await makeRequest(endpoint: "/project-vendors/\(projectVendorId)/escrow", method: "POST", body: body)
    }
    
    func getEscrow(_ escrowId: Int) async throws -> Escrow {
        return try await makeRequest(endpoint: "/escrow/\(escrowId)")
    }
    
    func fundEscrow(escrowId: Int, paymentMethodId: String) async throws -> FundEscrowResponse {
        let body: [String: Any] = ["paymentMethodId": paymentMethodId]
        return try await makeRequest(endpoint: "/escrow/\(escrowId)/fund", method: "POST", body: body)
    }
    
    func releaseMilestone(escrowId: Int, milestoneId: Int) async throws -> ReleaseMilestoneResponse {
        return try await makeRequest(endpoint: "/escrow/\(escrowId)/milestone/\(milestoneId)/release", method: "POST")
    }
    
    // MARK: - RFP Endpoints
    
    // Create standalone RFP (no project required)
    func createRFP(body: [String: Any]) async throws -> RFP {
        return try await makeRequest(
            endpoint: "/rfps",
            method: "POST",
            body: body
        )
    }
    
    // Create RFP under a project
    func createRFP(projectId: Int, body: [String: Any]) async throws -> RFP {
        return try await makeRequest(
            endpoint: "/projects/\(projectId)/rfps",
            method: "POST",
            body: body
        )
    }
    
    // Get all RFPs for current user (standalone + project-based)
    func getMyRFPs() async throws -> [RFP] {
        return try await makeRequest(
            endpoint: "/rfps/my",
            method: "GET"
        )
    }
    
    func getRFPsForProject(_ projectId: Int) async throws -> [RFP] {
        return try await makeRequest(
            endpoint: "/projects/\(projectId)/rfps",
            method: "GET"
        )
    }
    
    func getRFP(_ rfpId: Int) async throws -> RFP {
        return try await makeRequest(
            endpoint: "/rfps/\(rfpId)",
            method: "GET"
        )
    }
    
    func updateRFP(rfpId: Int, body: [String: Any]) async throws -> RFP {
        return try await makeRequest(
            endpoint: "/rfps/\(rfpId)",
            method: "PATCH",
            body: body
        )
    }
    
    func browseOpenRFPs() async throws -> [RFP] {
        return try await makeRequest(
            endpoint: "/rfps/browse",
            method: "GET"
        )
    }
    
    // MARK: - Bid Endpoints
    
    func submitBid(rfpId: Int, body: [String: Any]) async throws -> Bid {
        return try await makeRequest(
            endpoint: "/rfps/\(rfpId)/bids",
            method: "POST",
            body: body
        )
    }
    
    func updateBid(bidId: Int, body: [String: Any]) async throws -> Bid {
        return try await makeRequest(
            endpoint: "/bids/\(bidId)",
            method: "PATCH",
            body: body
        )
    }
    
    func acceptBid(bidId: Int) async throws -> AcceptBidResponse {
        return try await makeRequest(
            endpoint: "/bids/\(bidId)/accept",
            method: "POST"
        )
    }
    
    func rejectBid(bidId: Int) async throws -> MessageResponse {
        return try await makeRequest(
            endpoint: "/bids/\(bidId)/reject",
            method: "POST"
        )
    }
    
    // Get vendor's submitted bids
    func getMyBids() async throws -> [Bid] {
        return try await makeRequest(
            endpoint: "/bids/my",
            method: "GET"
        )
    }
    
    // MARK: - Vendor Marketplace

    func searchVendors(query: String? = nil, service: String? = nil, location: String? = nil) async throws -> [User] {
        var components = URLComponents(string: "\(baseURL)/vendors/search")!
        var queryItems: [URLQueryItem] = []
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        if let service = service {
            queryItems.append(URLQueryItem(name: "service", value: service))
        }
        if let location = location {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        // Note: /vendors/search doesn't require auth based on current backend

        print("🌐 Vendor search URL: \(components.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("❌ Vendor search failed with status: \(statusCode)")
            throw APIError.serverError("Failed to search vendors")
        }

        print("📦 Vendor search response: \(String(data: data, encoding: .utf8) ?? "nil")")

        do {
            let result = try JSONDecoder().decode([User].self, from: data)
            print("✅ Decoded \(result.count) vendors")
            return result
        } catch {
            print("❌ Decoding error: \(error)")
            throw error
        }
    }

    func getVendorProfile(vendorId: Int) async throws -> User {
        var request = URLRequest(url: URL(string: "\(baseURL)/vendors/\(vendorId)")!)
        request.httpMethod = "GET"
        // Note: /vendors/:id doesn't require auth based on current backend
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to fetch vendor profile")
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }

    func inviteVendorToRFP(rfpId: Int, vendorId: Int) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/rfps/\(rfpId)/invite")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["vendorId": vendorId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error ?? "Failed to invite vendor")
            }
            throw APIError.serverError("Failed to invite vendor")
        }
    }
    
    // MARK: - Messaging

    func getConversations() async throws -> [Conversation] {
        var request = URLRequest(url: URL(string: "\(baseURL)/conversations")!)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to fetch conversations")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Conversation].self, from: data)
    }

    func getMessages(with userId: Int) async throws -> [Message] {
        var request = URLRequest(url: URL(string: "\(baseURL)/messages/\(userId)")!)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to fetch messages")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Message].self, from: data)
    }

    func sendMessage(to receiverId: Int, content: String) async throws -> Message {
        var request = URLRequest(url: URL(string: "\(baseURL)/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["receiverId": receiverId, "content": content] as [String: Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to send message")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Message.self, from: data)
    }
    
    // MARK: - User Profile

    func getCurrentUser() async throws -> User {
        var request = URLRequest(url: URL(string: "\(baseURL)/users/me")!)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to fetch user")
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }

    func updateVendorProfile(
        name: String,
        bio: String?,
        location: String?,
        phoneNumber: String?,
        services: [String],
        portfolioUrls: [String],
        profileImageUrl: String?,
        startingPrice: Int?,
        instagramHandle: String?,
        websiteUrl: String?,
        yearsInBusiness: Int?
    ) async throws {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "name": name,
            "services": services,
            "portfolioUrls": portfolioUrls
        ]
        
        // Handle optional fields - send null to clear them
        body["bio"] = bio ?? NSNull()
        body["location"] = location ?? NSNull()
        body["phoneNumber"] = phoneNumber ?? NSNull()
        body["profileImageUrl"] = profileImageUrl ?? NSNull()
        body["startingPrice"] = startingPrice ?? NSNull()
        body["instagramHandle"] = instagramHandle ?? NSNull()
        body["websiteUrl"] = websiteUrl ?? NSNull()
        body["yearsInBusiness"] = yearsInBusiness ?? NSNull()
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Update profile error: \(errorBody)")
            throw APIError.serverError("Failed to update profile")
        }
        
        print("✅ Profile updated successfully")
    }
}

// MARK: - Error Type

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(Int)
    case serverError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .serverError(let message):
            return message
        case .decodingError(let details):
            return "Failed to parse response: \(details)"
        }
    }
}

// MARK: - Response Models

struct ConnectStatus: Codable {
    let connected: Bool
    let accountId: String?
    let chargesEnabled: Bool
    let payoutsEnabled: Bool
    let detailsSubmitted: Bool?
}

struct OnboardResponse: Codable {
    let url: String
    let accountId: String?
}

struct ProjectVendorResponse: Codable {
    let id: Int
    let projectId: Int
    let vendorId: Int
    let role: String
    let amountCents: Int
    let status: String
}

struct EscrowResponse: Codable {
    let id: Int
    let projectVendorId: Int
    let amountCents: Int
    let status: String
}

struct FundEscrowResponse: Codable {
    let status: String
    let paymentIntentId: String?
    let clientSecret: String?
    let amountCapturable: Int?
    let platformFee: Int?
}

struct ReleaseMilestoneResponse: Codable {
    let success: Bool
    let paymentIntentId: String
    let amountCaptured: Int
    let remainingCapturable: Int
    let message: String?
}

struct AcceptBidResponse: Codable {
    let projectVendor: ProjectVendor
    let message: String?
}

struct MessageResponse: Codable {
    let message: String
}

// MARK: - Notification

extension Notification.Name {
    static let userUnauthorized = Notification.Name("userUnauthorized")
}

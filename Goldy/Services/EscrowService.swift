//
//  EscrowService.swift
//  Goldy
//
//  Created by Blair Myers on 6/30/25.
//

import Foundation

enum EscrowService {
    static let base = URL(string: "https://go-hard-backend-production.up.railway.app")!

    struct FundRequest: Encodable { let escrowId: Int; let paymentMethodId: String }
    struct FundResponse: Decodable {
        let status: String
        let clientSecret: String?
        let paymentIntentId: String
        let amountCapturable: Int?
    }

    struct ReleaseRequest: Encodable { let escrowId: Int; let milestoneId: Int }
    struct ReleaseResponse: Decodable { let success: Bool; let paymentIntentId: String; let remaining: Int? }

    // MARK: - High-level APIs

    static func myEscrows(token: String) async throws -> [EscrowDTO] {
        print("🌐 DEBUG: Making request to escrows/byUser")
        print("🔑 DEBUG: Token prefix: \(String(token.prefix(20)))...")
        return try await request("escrows/byUser", method: "GET", token: token)
    }

    static func fund(escrowId: Int, paymentMethodId: String, token: String) async throws -> FundResponse {
        try await request("escrow/fund",
                          method: "POST",
                          body: FundRequest(escrowId: escrowId, paymentMethodId: paymentMethodId),
                          token: token)
    }

    static func release(escrowId: Int, milestoneId: Int, token: String) async throws -> ReleaseResponse {
        try await request("escrow/milestone/release",
                          method: "POST",
                          body: ReleaseRequest(escrowId: escrowId, milestoneId: milestoneId),
                          token: token)
    }

    /// Callback-style helper used by older code paths (maps DTOs → `EscrowProject`)
    static func fetchEscrows(token: String, completion: @escaping ([EscrowProject]) -> Void) {
        print("📡 DEBUG: fetchEscrows called with token: \(token.isEmpty ? "EMPTY" : "Present")")
        
        Task {
            do {
                print("⏳ DEBUG: Starting async request...")
                let dtos = try await myEscrows(token: token)
                print("✅ DEBUG: Received \(dtos.count) DTOs from backend")
                
                let projects = dtos.map { dto in
                    let project = dto.toProject()
                    print("🔄 DEBUG: Mapped DTO id:\(dto.id) -> Project '\(project.title)'")
                    return project
                }
                
                print("📦 DEBUG: Final projects array has \(projects.count) items")
                await MainActor.run {
                    print("🔄 DEBUG: Calling completion with \(projects.count) projects")
                    completion(projects)
                }
            } catch {
                print("❌ DEBUG: fetchEscrows error: \(error)")
                if let nsError = error as NSError? {
                    print("❌ DEBUG: Error code: \(nsError.code)")
                    print("❌ DEBUG: Error description: \(nsError.localizedDescription)")
                }
                await MainActor.run {
                    print("🔄 DEBUG: Calling completion with empty array due to error")
                    completion([])
                }
            }
        }
    }

    // MARK: - Core networking

    private static func request<T: Decodable, B: Encodable>(
        _ path: String, method: String, body: B? = nil, token: String
    ) async throws -> T {
        let url = base.appendingPathComponent(path)
        print("🌐 DEBUG: Making \(method) request to: \(url)")
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let body {
            req.httpBody = try JSONEncoder().encode(body)
            print("📤 DEBUG: Request has body")
        }

        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse else {
            print("❌ DEBUG: Response is not HTTPURLResponse")
            throw NSError(domain: "EscrowService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        print("📡 DEBUG: HTTP Status: \(http.statusCode)")
        print("📡 DEBUG: Response data size: \(data.count) bytes")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 DEBUG: Response body: \(responseString)")
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ DEBUG: HTTP error \(http.statusCode): \(msg)")
            throw NSError(
                domain: "EscrowService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            print("✅ DEBUG: Successfully decoded response")
            return decoded
        } catch {
            print("❌ DEBUG: JSON decoding error: \(error)")
            throw error
        }
    }

    private static func request<T: Decodable>(_ path: String, method: String, token: String) async throws -> T {
        try await request(path, method: method, body: Optional<Int>.none, token: token)
    }
}

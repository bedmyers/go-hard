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
        try await request("escrows/byUser", method: "GET", token: token)
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
        Task {
            do {
                let dtos = try await myEscrows(token: token)
                let projects = dtos.map { $0.toProject() }
                await MainActor.run { completion(projects) }
            } catch {
                print("❌ fetchEscrows error:", error.localizedDescription)
                await MainActor.run { completion([]) }
            }
        }
    }

    // MARK: - Core networking

    private static func request<T: Decodable, B: Encodable>(
        _ path: String, method: String, body: B? = nil, token: String
    ) async throws -> T {
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body { req.httpBody = try JSONEncoder().encode(body) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "EscrowService",
                code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func request<T: Decodable>(_ path: String, method: String, token: String) async throws -> T {
        try await request(path, method: method, body: Optional<Int>.none, token: token)
    }
}

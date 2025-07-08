//
//  EscrowService.swift
//  Goldy
//
//  Created by Blair Myers on 6/30/25.
//

import Foundation

struct BackendEscrow: Codable {
    let id: Int
    let title: String?
    let amount: Double
    let milestones: [BackendMilestone]
}

struct BackendMilestone: Codable {
    let amount: Double
    let released: Bool
}

func fetchEscrows(token: String, completion: @escaping ([EscrowProject]) -> Void) {
    guard let url = URL(string: "https://go-hard-backend-production.up.railway.app/escrows/byUser") else {
        print("❌ Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    print("🔑 Token used:", token)

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Network error:", error.localizedDescription)
            return
        }

        guard let data = data else {
            print("❌ No data returned")
            return
        }
        
        print("🔍 RAW RESPONSE:")
        print(String(data: data, encoding: .utf8) ?? "Unable to decode response")

        do {
            let backendEscrows = try JSONDecoder().decode([BackendEscrow].self, from: data)

            let projects = backendEscrows.map { escrow in
                EscrowProject(
                    id: escrow.id,
                    title: escrow.title ?? "Title",
                    subtitle: "FINAL DELIVERY TBD", // Customize this later
                    progress: calculateProgress(from: escrow.milestones),
                    totalCommitted: escrow.amount
                )
            }

            DispatchQueue.main.async {
                completion(projects)
            }
        } catch {
            print("❌ Decoding error:", error)
        }
    }.resume()
}

func calculateProgress(from milestones: [BackendMilestone]) -> Double {
    let total = milestones.reduce(0) { $0 + $1.amount }
    let released = milestones.filter { $0.released }.reduce(0) { $0 + $1.amount }
    return total > 0 ? released / total : 0
}

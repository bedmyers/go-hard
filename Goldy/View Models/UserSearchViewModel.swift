//
//  UserSearchViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 7/8/25.
//

import Foundation

class UserSearchViewModel: ObservableObject {
    @Published var results: [User] = []

    func searchUsers(query: String, token: String) {
        guard let url = URL(string: "https://go-hard-backend-production.up.railway.app/users/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            print("Invalid search URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                print("No data in response")
                return
            }

            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                DispatchQueue.main.async {
                    self.results = users
                }
            } catch {
                print("Failed to decode users:", error)
            }
        }.resume()
    }
}

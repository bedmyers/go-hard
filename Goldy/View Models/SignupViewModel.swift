//
//  SignupViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI
import Combine

class SignupViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var isSignedUp: Bool = false
    @Published var errorMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    func signUp() {
        guard let url = URL(string: "https://escrow-backend-production.up.railway.app/users/register") else { return }
        
        let body: [String: Any] = [
            "email": email,
            "name": name,
            "password": password
        ]
        
        let requestBody = try? JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = "Signup failed: \(error.localizedDescription)"
                }
            } receiveValue: { user in
                self.isSignedUp = true
            }
            .store(in: &self.cancellables)
    }
}

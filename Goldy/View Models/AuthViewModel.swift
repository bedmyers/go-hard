//
//  AuthViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    // Store your token
    @Published var token: String? {
        didSet {
            // Whenever token changes, we can say the user is “authenticated”
            isAuthenticated = (token != nil)
            // You might want to persist token in Keychain or UserDefaults for a real app
        }
    }
    
    func login() {
        guard let url = URL(string: "https://escrow-backend-production.up.railway.app/users/login") else { return }
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        let requestBody = try? JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // Check status
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                // Handle error
                if case .failure(let error) = completion {
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                }
            } receiveValue: { loginResponse in
                // Save the token
                self.token = loginResponse.token
            }
            .store(in: &self.cancellables)
    }
}

// Decoding the JSON response from /users/login
struct LoginResponse: Decodable {
    let token: String
    let userId: Int
    let email: String
}

//
//  UserSearchViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 7/8/25.
//

import Foundation
import Combine

class UserSearchViewModel: ObservableObject {
    @Published var results: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var searchTask: Task<Void, Never>?
    private let minQueryLength = 2
    
    func searchUsers(query: String, token: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        // Clear previous error
        errorMessage = nil
        
        // Validate input
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            return
        }
        
        guard query.count >= minQueryLength else {
            results = []
            return
        }
        
        guard !token.isEmpty else {
            errorMessage = "Authentication required"
            return
        }
        
        // Start new search
        searchTask = Task {
            await performSearch(query: query, token: token)
        }
    }
    
    @MainActor
    private func performSearch(query: String, token: String) async {
        isLoading = true
        
        do {
            let users = try await searchUsersAsync(query: query, token: token)
            
            // Only update if task wasn't cancelled
            if !Task.isCancelled {
                self.results = users
                self.errorMessage = nil
            }
        } catch {
            if !Task.isCancelled {
                self.results = []
                self.handleError(error)
            }
        }
        
        if !Task.isCancelled {
            isLoading = false
        }
    }
    
    private func searchUsersAsync(query: String, token: String) async throws -> [User] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://go-hard-backend-production.up.railway.app/users/search?query=\(encodedQuery)") else {
            throw UserSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        //request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                break
            case 401:
                throw UserSearchError.unauthorized
            case 404:
                return [] // No users found
            case 500...599:
                throw UserSearchError.serverError
            default:
                throw UserSearchError.networkError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Parse response
        do {
            let users = try JSONDecoder().decode([User].self, from: data)
            return users
        } catch {
            throw UserSearchError.decodingError(error.localizedDescription)
        }
    }
    
    private func handleError(_ error: Error) {
        switch error {
        case UserSearchError.unauthorized:
            errorMessage = "Session expired. Please log in again."
        case UserSearchError.serverError:
            errorMessage = "Server error. Please try again later."
        case UserSearchError.networkError(let message):
            errorMessage = "Network error: \(message)"
        case UserSearchError.decodingError:
            errorMessage = "Failed to process search results."
        case UserSearchError.invalidURL:
            errorMessage = "Invalid search query."
        default:
            if error.localizedDescription.contains("offline") {
                errorMessage = "No internet connection."
            } else {
                errorMessage = "Search failed. Please try again."
            }
        }
    }
    
    func clearResults() {
        searchTask?.cancel()
        results = []
        errorMessage = nil
        isLoading = false
    }
}

// MARK: - Error Types

enum UserSearchError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError
    case networkError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .unauthorized:
            return "Authentication failed"
        case .serverError:
            return "Server error"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Data parsing error: \(message)"
        }
    }
}

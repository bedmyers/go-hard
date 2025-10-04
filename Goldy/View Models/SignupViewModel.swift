//
//  SignupViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI
import Combine

class SignupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var isSignedUp: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://go-hard-backend-production.up.railway.app"
    
    // MARK: - Validation Computed Properties
    var emailValidationState: ValidationState {
        if email.isEmpty { return .none }
        if isValidEmail(email) { return .valid }
        return .invalid("Invalid email format")
    }
    
    var nameValidationState: ValidationState {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return .none }
        if trimmedName.count >= 2 { return .valid }
        return .invalid("Too short")
    }
    
    var passwordValidationState: ValidationState {
        if password.isEmpty { return .none }
        if isValidPassword(password) { return .valid }
        return .invalid("Too weak")
    }
    
    var canSubmit: Bool {
        if case .valid = emailValidationState,
           case .valid = nameValidationState,
           case .valid = passwordValidationState,
           !isLoading {
            return true
        }
        return false
    }
    
    // MARK: - Public Methods
    func signUp() {
        guard canSubmit else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        errorMessage = ""
        isLoading = true
        
        guard let url = URL(string: "\(baseURL)/users/register") else {
            errorMessage = "Invalid server URL"
            isLoading = false
            return
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let body: [String: Any] = [
            "email": trimmedEmail,
            "name": trimmedName,
            "password": password
        ]
        
        guard let requestBody = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Failed to prepare request"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                print("Status Code:", httpResponse.statusCode)
                
                switch httpResponse.statusCode {
                case 200, 201:
                    return data
                case 400:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.badRequest(errorResponse.message)
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        throw NetworkError.badRequest(errorString)
                    } else {
                        throw NetworkError.badRequest("Invalid request")
                    }
                case 409:
                    throw NetworkError.conflict("An account with this email already exists")
                case 422:
                    throw NetworkError.validationFailed("Please check your input")
                case 500...599:
                    throw NetworkError.serverError
                default:
                    let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("Backend Error Body:", responseBody)
                    throw NetworkError.unknownError
                }
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())  // Reuse LoginResponse
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] loginResponse in
                print("Signup successful for user: \(loginResponse.email)")
                
                // Save token and userId
                UserDefaults.standard.set(loginResponse.token, forKey: "authToken")
                UserDefaults.standard.set(loginResponse.userId, forKey: "userId")
                UserDefaults.standard.set(loginResponse.email, forKey: "userEmail")
                
                self?.isSignedUp = true
                self?.clearForm()
            }
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8 &&
               password.contains(where: { $0.isUppercase }) &&
               password.contains(where: { $0.isLowercase }) &&
               password.contains(where: { $0.isNumber })
    }
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .badRequest(let message):
                errorMessage = message
            case .conflict(let message):
                errorMessage = message
            case .validationFailed(let message):
                errorMessage = message
            case .serverError:
                errorMessage = "Server error. Please try again later."
            case .invalidResponse:
                errorMessage = "Invalid server response"
            case .unknownError:
                errorMessage = "Something went wrong. Please try again."
            case .unauthorized(_):
                errorMessage = "Something went wrong. Please try again."
            case .notFound(_):
                errorMessage = "Something went wrong. Please try again."
            }
        } else if let decodingError = error as? DecodingError {
            print("Decoding error:", decodingError)
            errorMessage = "Unexpected response from server"
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "No internet connection"
            case .timedOut:
                errorMessage = "Request timed out. Please try again."
            default:
                errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } else {
            errorMessage = "Signup failed: \(error.localizedDescription)"
        }
    }
    
    private func clearForm() {
        email = ""
        name = ""
        password = ""
        errorMessage = ""
    }
}

// MARK: - Supporting Types
enum ValidationState {
    case none
    case valid
    case invalid(String)
    
    var isInvalid: Bool {
        if case .invalid = self { return true }
        return false
    }
}

// MARK: - Response Models
struct ErrorResponse: Codable {
    let message: String
    let error: String?
    let statusCode: Int?
}

//
//  AuthViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @AppStorage("authToken") private var storedAuthToken: String = ""
    @AppStorage("userId") private var storedUserId: Int = 0
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "https://go-hard-backend-production.up.railway.app"
    
    @Published var token: String? {
        didSet {
            isAuthenticated = (token != nil)
            if let token = token {
                storedAuthToken = token
            }
        }
    }
    
    // MARK: - Validation Computed Properties
    var emailValidationState: ValidationState {
        if email.isEmpty { return .none }
        if isValidEmail(email) { return .valid }
        return .invalid("Invalid email format")
    }
    
    var passwordValidationState: ValidationState {
        if password.isEmpty { return .none }
        if password.count >= 6 { return .valid }
        return .invalid("Too short")
    }
    
    var canSubmit: Bool {
        if case .valid = emailValidationState,
           !password.isEmpty,
           !isLoading {
            return true
        }
        return false
    }
    
    // MARK: - Public Methods
    func login() {
        guard canSubmit else {
            errorMessage = "Please enter your email and password"
            return
        }
        
        errorMessage = ""
        isLoading = true
        
        guard let url = URL(string: "\(baseURL)/users/login") else {
            errorMessage = "Invalid server URL"
            isLoading = false
            return
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        let body: [String: Any] = [
            "email": trimmedEmail,
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
                
                print("Login Status Code:", httpResponse.statusCode)
                
                switch httpResponse.statusCode {
                case 200, 201:
                    return data
                case 401:
                    throw NetworkError.unauthorized("Invalid email or password")
                case 404:
                    throw NetworkError.notFound("Account not found")
                case 422:
                    throw NetworkError.validationFailed("Please check your credentials")
                case 500...599:
                    throw NetworkError.serverError
                default:
                    let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("Login Error Body:", responseBody)
                    throw NetworkError.unknownError
                }
            }
            .decode(type: LoginResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] loginResponse in
                print("✅ Login successful for user: \(loginResponse.email)")
                print("✅ Token stored: \(loginResponse.token)")
                print("✅ UserId stored: \(loginResponse.userId)")
                
                self?.token = loginResponse.token
                self?.storedUserId = loginResponse.userId
                UserDefaults.standard.set(loginResponse.email, forKey: "userEmail")
                UserDefaults.standard.set(loginResponse.userId, forKey: "userId")
                UserDefaults.standard.set(loginResponse.token, forKey: "authToken")
                
                self?.clearForm()
                
                self?.isAuthenticated = true
            }
            .store(in: &cancellables)
    }
    
    func forgotPassword() {
        guard case .valid = emailValidationState else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        // TODO: Implement forgot password API call
        errorMessage = "Password reset link sent to \(email)"
    }
    
    func logout() {
        token = nil
        storedAuthToken = ""
        storedUserId = 0
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        isAuthenticated = false
        clearForm()
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
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized(let message):
                errorMessage = message
            case .notFound(let message):
                errorMessage = message
            case .validationFailed(let message):
                errorMessage = message
            case .serverError:
                errorMessage = "Server error. Please try again later."
            case .invalidResponse:
                errorMessage = "Invalid server response"
            default:
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
                errorMessage = "Network error. Please try again."
            }
        } else {
            errorMessage = "Login failed. Please try again."
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        errorMessage = ""
    }
}

// MARK: - Response Model
struct LoginResponse: Decodable {
    let token: String
    let userId: Int
    let email: String
}

// MARK: - Network Errors (shared with SignupViewModel)
enum NetworkError: Error {
    case unauthorized(String)
    case notFound(String)
    case badRequest(String)
    case conflict(String)
    case validationFailed(String)
    case serverError
    case invalidResponse
    case unknownError
}

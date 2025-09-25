//
//  AppState.swift
//  Goldy
//
//  Created by Blair Myers on 6/28/25.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    
    init() {
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        let authToken = UserDefaults.standard.string(forKey: "authToken") ?? ""
        let userId = UserDefaults.standard.integer(forKey: "userId")
        
        print("DEBUG: Checking auth - Token exists: \(authToken.isEmpty ? "NO" : "YES")")
        print("DEBUG: Checking auth - User ID: \(userId)")
        
        // Only require a valid token for initial auth check
        // userId might not be set until after login
        isAuthenticated = !authToken.isEmpty
        
        print("DEBUG: Authentication status: \(isAuthenticated ? "AUTHENTICATED" : "NOT AUTHENTICATED")")
    }
    
    func login(token: String, userId: Int) {
        print("DEBUG: AppState.login called with userId: \(userId)")
        
        UserDefaults.standard.set(token, forKey: "authToken")
        UserDefaults.standard.set(userId, forKey: "userId")
        
        isAuthenticated = true
        print("DEBUG: User logged in successfully - isAuthenticated: \(isAuthenticated)")
    }
    
    func logout() {
        print("DEBUG: AppState.logout called")
        
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        
        isAuthenticated = false
        print("DEBUG: User logged out - isAuthenticated: \(isAuthenticated)")
    }
}

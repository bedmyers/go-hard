//
//  AppState.swift
//  Goldy
//
//  Created by Blair Myers on 6/28/25.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    init() {
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        let authToken = UserDefaults.standard.string(forKey: "authToken") ?? ""
        let userId = UserDefaults.standard.integer(forKey: "userId")
        let userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        let userTypeString = UserDefaults.standard.string(forKey: "userType") ?? "CUSTOMER"
        
        print("DEBUG: Checking auth - Token exists: \(authToken.isEmpty ? "NO" : "YES")")
        print("DEBUG: Checking auth - User ID: \(userId)")
        print("DEBUG: Checking auth - User Type: \(userTypeString)")
        
        isAuthenticated = !authToken.isEmpty
        
        if isAuthenticated && userId > 0 {
            let userType = User.UserType(rawValue: userTypeString) ?? .customer
            currentUser = User(
                id: userId,
                email: userEmail,
                name: userName,
                userType: userType
            )
        }
        
        print("DEBUG: Authentication status: \(isAuthenticated ? "AUTHENTICATED" : "NOT AUTHENTICATED")")
        print("DEBUG: Current user: \(currentUser?.email ?? "none")")
    }
    
    func login(token: String, userId: Int, email: String, name: String, userType: String) {
        print("DEBUG: AppState.login called with userId: \(userId), userType: \(userType)")
        
        UserDefaults.standard.set(token, forKey: "authToken")
        UserDefaults.standard.set(userId, forKey: "userId")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(userType, forKey: "userType")
        
        let parsedUserType = User.UserType(rawValue: userType) ?? .customer
        currentUser = User(
            id: userId,
            email: email,
            name: name,
            userType: parsedUserType
        )
        
        isAuthenticated = true
        print("DEBUG: User logged in successfully - isAuthenticated: \(isAuthenticated)")
        print("DEBUG: User type: \(userType)")
    }
    
    func logout() {
        print("DEBUG: AppState.logout called")
        
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userType")
        
        currentUser = nil
        isAuthenticated = false
        print("DEBUG: User logged out - isAuthenticated: \(isAuthenticated)")
    }
}

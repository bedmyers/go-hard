//
//  VendorOnboardingViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import Foundation
import SwiftUI

@MainActor
class VendorOnboardingViewModel: ObservableObject {
    @Published var status: ConnectStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var onboardingURL: URL?
    @Published var showingOnboarding = false
    
    private let connectService = APIService.shared
    
    var needsOnboarding: Bool {
        guard let status = status else { return true }
        return !status.connected || !status.chargesEnabled
    }
    
    func checkStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            status = try await connectService.getConnectStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func startOnboarding() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await connectService.startOnboarding()
            onboardingURL = URL(string: response.url)
            showingOnboarding = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func openDashboard() async {
        do {
            let response = try await connectService.getDashboardLink()
            if let url = URL(string: response.url) {
                await UIApplication.shared.open(url)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

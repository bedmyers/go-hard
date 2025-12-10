//
//  VendorMarketplaceViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 12/7/25.
//

import SwiftUI

@MainActor
class VendorMarketplaceViewModel: ObservableObject {
    @Published var vendors: [User] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var selectedCategory: VendorCategory?
    @Published var selectedLocation: String?
    @Published var portfolioOnly = false
    
    let locations = [
        "Detroit, MI",
        "Chicago, IL",
        "Los Angeles, CA",
        "New York, NY",
        "Austin, TX",
        "Miami, FL",
        "Denver, CO",
        "Seattle, WA"
    ]
    
    var hasActiveFilters: Bool {
        selectedLocation != nil || portfolioOnly
    }
    
    var filteredVendors: [User] {
        var result = vendors
        
        if portfolioOnly {
            result = result.filter { vendor in
                guard let urls = vendor.portfolioUrls else { return false }
                return !urls.isEmpty
            }
        }
        
        return result
    }
    
    func search() async {
        isLoading = true
        
        do {
            vendors = try await APIService.shared.searchVendors(
                query: searchQuery.isEmpty ? nil : searchQuery,
                service: selectedCategory?.searchTerm,
                location: selectedLocation
            )
        } catch {
            print("❌ Error searching vendors: \(error)")
        }
        
        isLoading = false
    }
    
    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        selectedLocation = nil
        portfolioOnly = false
    }
}

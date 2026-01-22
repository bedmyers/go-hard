//
//  VendorMarketplaceViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 12/7/25.
//

import SwiftUI
import Combine

@MainActor
class VendorMarketplaceViewModel: ObservableObject {
    @Published var vendors: [User] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var selectedCategory: VendorCategory?
    @Published var selectedLocation: String?
    @Published var portfolioOnly = false

    private var searchTask: Task<Void, Never>?

    let locations = [
        "Detroit, MI",
        "Chicago, IL"
    ]

    /// Debounced search - call this when searchQuery changes
    func debouncedSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            guard !Task.isCancelled else { return }
            await search()
        }
    }
    
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

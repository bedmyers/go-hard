//
//  VendorMarketplace.swift
//  Goldy
//
//  Created by Blair Myers on 12/7/25.
//

import SwiftUI

struct VendorMarketplaceView: View {
    @StateObject private var viewModel = VendorMarketplaceViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding()
                    
                    // Category filters
                    categoryFilters
                    
                    // Results
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.vendors.isEmpty {
                        emptyState
                    } else {
                        vendorList
                    }
                }
            }
            .navigationTitle("Find Vendors")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: User.self) { vendor in
                VendorProfileView(vendorId: vendor.id)
            }
        }
        .task {
            await viewModel.search()
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search vendors...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await viewModel.search() }
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                        Task { await viewModel.search() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            
            // Location filter
            Menu {
                Button("All Locations") {
                    viewModel.selectedLocation = nil
                    Task { await viewModel.search() }
                }
                ForEach(viewModel.locations, id: \.self) { location in
                    Button(location) {
                        viewModel.selectedLocation = location
                        Task { await viewModel.search() }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                    if let location = viewModel.selectedLocation {
                        Text(location.components(separatedBy: ",").first ?? location)
                            .lineLimit(1)
                    }
                }
                .font(.custom("Spectral-Medium", size: 14))
                .foregroundColor(viewModel.selectedLocation != nil ? .white : Color(hex: "3B82F6"))
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(viewModel.selectedLocation != nil ? Color(hex: "3B82F6") : Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Category Filters
    
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                    Task { await viewModel.search() }
                }
                
                ForEach(VendorCategory.allCases) { category in
                    CategoryPill(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                        Task { await viewModel.search() }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Vendor List
    
    private var vendorList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("\(viewModel.vendors.count) vendor\(viewModel.vendors.count == 1 ? "" : "s") found")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ForEach(viewModel.vendors) { vendor in
                    NavigationLink(value: vendor) {
                        VendorCard(vendor: vendor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.search()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .font(.custom("Spectral-Regular", size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Vendors Found")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Try adjusting your filters or search terms")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.clearFilters()
                Task { await viewModel.search() }
            } label: {
                Text("Clear Filters")
                    .font(.custom("Spectral-Bold", size: 14))
                    .foregroundColor(Color(hex: "3B82F6"))
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Category Pill

private struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.custom("Spectral-Regular", size: 12))
                Text(title)
                    .font(.custom("Spectral-Medium", size: 13))
            }
            .foregroundColor(isSelected ? .black : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "FFD700") : Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.04), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Vendor Card

private struct VendorCard: View {
    let vendor: User
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "FFD700").opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Text(initials)
                    .font(.custom("DelaGothicOne-Regular", size: 20))
                    .foregroundColor(Color(hex: "B8860B"))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(vendor.name)
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
                
                if let services = vendor.services, !services.isEmpty {
                    Text(services.prefix(2).joined(separator: " • "))
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .lineLimit(1)
                }
                
                if let location = vendor.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.custom("Spectral-Regular", size: 10))
                        Text(location)
                            .font(.custom("Spectral-Regular", size: 12))
                    }
                    .foregroundColor(.gray)
                }
                
                if let bio = vendor.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.custom("Spectral-Medium", size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var initials: String {
        let parts = vendor.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(vendor.name.prefix(2)).uppercased()
    }
}

// MARK: - Vendor Category

enum VendorCategory: String, CaseIterable, Identifiable {
    case photographer
    case videographer
    case florist
    case catering
    case dj
    case band
    case cake
    case venue
    case planner
    case officiant
    case hair
    case makeup
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .photographer: return "Photo"
        case .videographer: return "Video"
        case .florist: return "Florist"
        case .catering: return "Catering"
        case .dj: return "DJ"
        case .band: return "Band"
        case .cake: return "Cake"
        case .venue: return "Venue"
        case .planner: return "Planner"
        case .officiant: return "Officiant"
        case .hair: return "Hair"
        case .makeup: return "Makeup"
        }
    }
    
    var icon: String {
        switch self {
        case .photographer: return "camera"
        case .videographer: return "video"
        case .florist: return "leaf"
        case .catering: return "fork.knife"
        case .dj: return "music.note"
        case .band: return "music.mic"
        case .cake: return "birthday.cake"
        case .venue: return "building.columns"
        case .planner: return "calendar"
        case .officiant: return "book.closed"
        case .hair: return "scissors"
        case .makeup: return "paintbrush"
        }
    }
    
    var searchTerm: String {
        rawValue
    }
}

// MARK: - Preview

#Preview {
    VendorMarketplaceView()
}

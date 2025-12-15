//
//  VendorEditProfileView.swift
//  Goldy
//
//  Created by Blair Myers on 12/11/25.
//
import SwiftUI
import PhotosUI

struct VendorEditProfileView: View {
    @StateObject private var viewModel = VendorEditProfileViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            profilePhotoSection
                            basicInfoSection
                            servicesSection
                            pricingSection
                            linksSection
                            portfolioSection
                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                }
                
                // Upload overlay
                if viewModel.isUploading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text(viewModel.uploadingMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.didSave {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.isUploading)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong")
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }
    
    // MARK: - Profile Photo
    
    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FFD700").opacity(0.2))
                    .frame(width: 120, height: 120)
                
                if let urlString = viewModel.profileImageUrl, !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "B8860B"))
                }
                
                // Camera overlay button
                PhotosPicker(selection: $viewModel.selectedProfilePhoto, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FFD700"))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                }
                .offset(x: 42, y: 42)
            }
            
            if viewModel.profileImageUrl != nil {
                Button {
                    viewModel.profileImageUrl = nil
                } label: {
                    Text("Remove Photo")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .onChange(of: viewModel.selectedProfilePhoto) { newValue in
            if newValue != nil {
                Task { await viewModel.uploadProfilePhoto() }
            }
        }
    }
    
    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BASIC INFO")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Business Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                TextField("Your business name", text: $viewModel.name)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Bio")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                TextEditor(text: Binding(
                    get: { viewModel.bio ?? "" },
                    set: { viewModel.bio = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 15))
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                .scrollContentBackground(.hidden)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Location")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                TextField("City, State", text: Binding(
                    get: { viewModel.location ?? "" },
                    set: { viewModel.location = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 15))
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Phone Number")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                TextField("(555) 123-4567", text: Binding(
                    get: { viewModel.phoneNumber ?? "" },
                    set: { viewModel.phoneNumber = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 15))
                .keyboardType(.phonePad)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Services
    
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SERVICES")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
            
            Text("Select all that apply")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(EditProfileServiceCategory.allCases) { category in
                    EditServiceChip(
                        title: category.displayName,
                        isSelected: viewModel.services.contains(category.rawValue)
                    ) {
                        if viewModel.services.contains(category.rawValue) {
                            viewModel.services.removeAll { $0 == category.rawValue }
                        } else {
                            viewModel.services.append(category.rawValue)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Pricing & Experience
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRICING & EXPERIENCE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Starting Price")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                HStack {
                    Text("$")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    TextField("e.g., 2500", text: $viewModel.startingPriceText)
                        .font(.system(size: 18))
                        .keyboardType(.numberPad)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                
                Text("This is your minimum starting price for couples to see")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Years in Business")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                
                HStack {
                    TextField("e.g., 5", text: $viewModel.yearsInBusinessText)
                        .font(.system(size: 18))
                        .keyboardType(.numberPad)
                    
                    Text("years")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Links
    
    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LINKS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundColor(Color(hex: "3B82F6"))
                    Text("Website")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                TextField("https://yourwebsite.com", text: Binding(
                    get: { viewModel.websiteUrl ?? "" },
                    set: { viewModel.websiteUrl = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(size: 15))
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "camera")
                        .foregroundColor(Color(hex: "E1306C"))
                    Text("Instagram Handle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("@")
                        .foregroundColor(.gray)
                    TextField("yourhandle", text: Binding(
                        get: { viewModel.instagramHandle ?? "" },
                        set: { viewModel.instagramHandle = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: 15))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Portfolio
    
    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PORTFOLIO")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text("\(viewModel.portfolioUrls.count) photos")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
                
                Spacer()
                
                PhotosPicker(
                    selection: $viewModel.selectedPortfolioPhotos,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Photos")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "3B82F6"))
                }
            }
            
            Text("Showcase your best work")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            if viewModel.portfolioUrls.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                    
                    Text("No portfolio photos yet")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    PhotosPicker(
                        selection: $viewModel.selectedPortfolioPhotos,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Text("Upload Photos")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "8B5CF6"))
                            .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(viewModel.portfolioUrls, id: \.self) { urlString in
                        ZStack(alignment: .topTrailing) {
                            if let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure(_):
                                        Color.gray.opacity(0.2)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            )
                                    case .empty:
                                        Color.gray.opacity(0.1)
                                            .overlay(ProgressView())
                                    @unknown default:
                                        Color.gray.opacity(0.1)
                                    }
                                }
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            
                            // Delete button
                            Button {
                                viewModel.portfolioUrls.removeAll { $0 == urlString }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.5))
        .cornerRadius(16)
        .onChange(of: viewModel.selectedPortfolioPhotos) { newValue in
            if !newValue.isEmpty {
                Task { await viewModel.uploadPortfolioPhotos() }
            }
        }
    }
}

// MARK: - Service Chip

private struct EditServiceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "8B5CF6") : Color.white)
                .cornerRadius(16)
        }
    }
}

// MARK: - Service Categories

private enum EditProfileServiceCategory: String, CaseIterable, Identifiable {
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
        case .dj: return "DJ"
        default: return rawValue.capitalized
        }
    }
}

// MARK: - View Model

@MainActor
class VendorEditProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var bio: String?
    @Published var location: String?
    @Published var phoneNumber: String?
    @Published var services: [String] = []
    @Published var portfolioUrls: [String] = []
    @Published var profileImageUrl: String?
    @Published var startingPriceText = ""
    @Published var instagramHandle: String?
    @Published var websiteUrl: String?
    @Published var yearsInBusinessText = ""
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var didSave = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    // Photo picker
    @Published var selectedProfilePhoto: PhotosPickerItem?
    @Published var selectedPortfolioPhotos: [PhotosPickerItem] = []
    @Published var isUploading = false
    @Published var uploadingMessage = "Uploading..."
    
    func loadProfile() async {
        isLoading = true
        do {
            let user = try await APIService.shared.getCurrentUser()
            name = user.name
            bio = user.bio
            location = user.location
            phoneNumber = user.phoneNumber
            services = user.services ?? []
            portfolioUrls = user.portfolioUrls ?? []
            profileImageUrl = user.profileImageUrl
            if let price = user.startingPrice {
                startingPriceText = "\(price / 100)"
            }
            instagramHandle = user.instagramHandle
            websiteUrl = user.websiteUrl
            if let years = user.yearsInBusiness {
                yearsInBusinessText = "\(years)"
            }
        } catch {
            print("❌ Error loading profile: \(error)")
        }
        isLoading = false
    }
    
    func uploadProfilePhoto() async {
        guard let item = selectedProfilePhoto else { return }
        
        isUploading = true
        uploadingMessage = "Uploading photo..."
        
        do {
            let data = try await CloudinaryService.shared.loadImageData(from: item)
            let url = try await CloudinaryService.shared.uploadImage(data)
            profileImageUrl = url
            selectedProfilePhoto = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isUploading = false
    }
    
    func uploadPortfolioPhotos() async {
        guard !selectedPortfolioPhotos.isEmpty else { return }
        
        isUploading = true
        let count = selectedPortfolioPhotos.count
        
        do {
            for (index, item) in selectedPortfolioPhotos.enumerated() {
                uploadingMessage = "Uploading \(index + 1) of \(count)..."
                let data = try await CloudinaryService.shared.loadImageData(from: item)
                let url = try await CloudinaryService.shared.uploadImage(data)
                portfolioUrls.append(url)
            }
            selectedPortfolioPhotos = []
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isUploading = false
    }
    
    func saveProfile() async {
        isSaving = true
        
        var startingPrice: Int? = nil
        if let price = Int(startingPriceText) {
            startingPrice = price * 100
        }
        
        var yearsInBusiness: Int? = nil
        if let years = Int(yearsInBusinessText) {
            yearsInBusiness = years
        }
        
        do {
            try await APIService.shared.updateVendorProfile(
                name: name,
                bio: bio,
                location: location,
                phoneNumber: phoneNumber,
                services: services,
                portfolioUrls: portfolioUrls,
                profileImageUrl: profileImageUrl,
                startingPrice: startingPrice,
                instagramHandle: instagramHandle,
                websiteUrl: websiteUrl,
                yearsInBusiness: yearsInBusiness
            )
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isSaving = false
    }
}

#Preview {
    VendorEditProfileView()
}

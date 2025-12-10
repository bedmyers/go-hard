//
//  VendorProfileView.swift
//  Goldy
//
//  Created by Blair Myers on 12/7/25.
//

import SwiftUI

struct VendorProfileView: View {
    let vendor: User
    @StateObject private var viewModel: VendorProfileViewModel
    @State private var showInviteSheet = false
    
    init(vendor: User) {
        self.vendor = vendor
        _viewModel = StateObject(wrappedValue: VendorProfileViewModel(vendorId: vendor.id))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                profileHeader
                
                // Services
                if let services = vendorData.services, !services.isEmpty {
                    servicesSection(services)
                }
                
                // Bio
                if let bio = vendorData.bio, !bio.isEmpty {
                    bioSection(bio)
                }
                
                // Portfolio
                if let urls = vendorData.portfolioUrls, !urls.isEmpty {
                    portfolioSection(urls)
                }
                
                // Contact & Invite
                actionButtons
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(hex: "F5F1E8"))
        .navigationTitle("Vendor Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showInviteSheet) {
            InviteToBidSheet(vendor: vendorData)
        }
        .task {
            await viewModel.loadFullProfile()
        }
    }
    
    private var vendorData: User {
        viewModel.fullProfile ?? vendor
    }
    
    // MARK: - Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "FFD700").opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(initials)
                    .font(.custom("DelaGothicOne-Regular", size: 32))
                    .foregroundColor(Color(hex: "B8860B"))
            }
            
            // Name
            Text(vendorData.name)
                .font(.custom("DelaGothicOne-Regular", size: 24))
            
            // Location
            if let location = vendorData.location {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color(hex: "3B82F6"))
                    Text(location)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(20)
    }
    
    // MARK: - Services
    
    private func servicesSection(_ services: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.custom("DelaGothicOne-Regular", size: 16))
            
            FlowLayout(spacing: 8) {
                ForEach(services, id: \.self) { service in
                    Text(service.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: "8B5CF6").opacity(0.1))
                        .cornerRadius(16)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Bio
    
    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.custom("DelaGothicOne-Regular", size: 16))
            
            Text(bio)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Portfolio
    
    private func portfolioSection(_ urls: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio")
                .font(.custom("DelaGothicOne-Regular", size: 16))
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(urls.indices, id: \.self) { index in
                    if let url = URL(string: urls[index]) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(minHeight: 120)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .cornerRadius(12)
                    } else {
                        // Show as link if not an image URL
                        Link(destination: URL(string: urls[index]) ?? URL(string: "https://google.com")!) {
                            HStack {
                                Image(systemName: "link")
                                Text("Portfolio Link")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "3B82F6"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "3B82F6").opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showInviteSheet = true
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("INVITE TO BID")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "FFD700"))
                .cornerRadius(12)
            }
            
            NavigationLink(destination: ChatView(partner: MessageUser(id: vendorData.id, name: vendorData.name, userType: vendorData.userType.rawValue))) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("MESSAGE")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                }
                .foregroundColor(Color(hex: "3B82F6"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "3B82F6").opacity(0.15))
                .cornerRadius(12)
            }
            
            if let phone = vendorData.phoneNumber, !phone.isEmpty {
                Link(destination: URL(string: "tel:\(phone)")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("CALL")
                            .font(.custom("DelaGothicOne-Regular", size: 14))
                    }
                    .foregroundColor(Color(hex: "22C55E"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "22C55E").opacity(0.15))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var initials: String {
        let parts = vendorData.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(vendorData.name.prefix(2)).uppercased()
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - View Model

@MainActor
class VendorProfileViewModel: ObservableObject {
    @Published var fullProfile: User?
    @Published var isLoading = false
    
    let vendorId: Int
    
    init(vendorId: Int) {
        self.vendorId = vendorId
    }
    
    func loadFullProfile() async {
        isLoading = true
        do {
            fullProfile = try await APIService.shared.getVendorProfile(vendorId: vendorId)
        } catch {
            print("❌ Error loading vendor profile: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Invite to Bid Sheet

struct InviteToBidSheet: View {
    let vendor: User
    @Environment(\.dismiss) var dismiss
    @State private var rfps: [RFP] = []
    @State private var isLoading = true
    @State private var selectedRFP: RFP?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if rfps.isEmpty {
                    noRFPsView
                } else {
                    rfpList
                }
            }
            .navigationTitle("Invite \(vendor.name.components(separatedBy: " ").first ?? "Vendor")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Invite Sent!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(vendor.name) has been invited to bid on your request.")
            }
        }
        .task {
            await loadMyRFPs()
        }
    }
    
    private var noRFPsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Open Requests")
                .font(.custom("DelaGothicOne-Regular", size: 18))
            
            Text("Create a request first, then you can invite vendors to bid on it.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var rfpList: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Select a request to invite this vendor to:")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(rfps.filter { $0.isOpen }) { rfp in
                    Button {
                        Task {
                            await inviteVendor(to: rfp)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rfp.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                Text(rfp.budgetFormatted)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "22C55E"))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(Color(hex: "FFD700"))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func loadMyRFPs() async {
        do {
            rfps = try await APIService.shared.getMyRFPs()
        } catch {
            print("❌ Error loading RFPs: \(error)")
        }
        isLoading = false
    }
    
    private func inviteVendor(to rfp: RFP) async {
        do {
            try await APIService.shared.inviteVendorToRFP(rfpId: rfp.id, vendorId: vendor.id)
            showSuccess = true
        } catch {
            print("❌ Error inviting vendor: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VendorProfileView(vendor: User(
            id: 1,
            email: "photo@example.com",
            name: "Sarah Chen Photography",
            userType: .vendor,
            bio: "Award-winning wedding photographer with 10 years of experience capturing beautiful moments. I specialize in natural light and candid shots.",
            services: ["photographer", "videographer"],
            portfolioUrls: ["https://picsum.photos/400/300", "https://picsum.photos/400/301"],
            location: "Detroit, MI",
            phoneNumber: "313-555-1234",
            stripeAccountId: nil
        ))
    }
}

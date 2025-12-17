//
//  VendorProfileView.swift
//  Goldy
//
//  Created by Blair Myers on 12/7/25.
//

import SwiftUI

struct VendorProfileView: View {
    let vendorId: Int
    @StateObject private var viewModel = VendorProfileViewModel()
    @State private var showInviteSheet = false
    @State private var selectedPhotoIndex: Int? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "F5F1E8")
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let vendor = viewModel.vendor {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection(vendor)
                        
                        if hasQuickStats(vendor) {
                            quickStatsRow(vendor)
                        }
                        
                        if let bio = vendor.bio, !bio.isEmpty {
                            bioSection(bio)
                        }
                        
                        if let services = vendor.services, !services.isEmpty {
                            servicesSection(services)
                        }
                        
                        if hasLinks(vendor) {
                            linksSection(vendor)
                        }
                        
                        if let photos = vendor.portfolioUrls, !photos.isEmpty {
                            portfolioSection(photos)
                        }
                        
                        actionButtons(vendor)
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.custom("Spectral-Regular", size: 40))
                        .foregroundColor(.gray)
                    Text(error)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Vendor Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadVendor(id: vendorId)
        }
        .sheet(isPresented: $showInviteSheet) {
            VendorInviteToRFPSheet(vendorId: vendorId, vendorName: viewModel.vendor?.name ?? "Vendor")
        }
        .fullScreenCover(item: $selectedPhotoIndex) { index in
            if let photos = viewModel.vendor?.portfolioUrls {
                PhotoGalleryView(photos: photos, initialIndex: index)
            }
        }
    }
    
    // MARK: - Header Section
    
    private func headerSection(_ vendor: User) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FFD700").opacity(0.2))
                    .frame(width: 100, height: 100)
                
                if let urlString = vendor.profileImageUrl, !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Text(vendor.initials)
                        .font(.custom("DelaGothicOne-Regular", size: 28))
                        .foregroundColor(Color(hex: "B8860B"))
                }
            }
            
            HStack(spacing: 8) {
                Text(vendor.name)
                    .font(.custom("DelaGothicOne-Regular", size: 22))
                
                if vendor.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "3B82F6"))
                        .font(.custom("Spectral-Regular", size: 18))
                }
            }
            
            if let location = vendor.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.custom("Spectral-Regular", size: 12))
                    Text(location)
                        .font(.custom("Spectral-Regular", size: 14))
                }
                .foregroundColor(.gray)
            }
            
            if let priceText = vendor.startingPriceFormatted {
                Text("Starting at \(priceText)")
                    .font(.custom("Spectral-Bold", size: 16))
                    .foregroundColor(Color(hex: "22C55E"))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
    }
    
    // MARK: - Quick Stats
    
    private func hasQuickStats(_ vendor: User) -> Bool {
        vendor.yearsInBusiness != nil || (vendor.portfolioUrls?.count ?? 0) > 0
    }
    
    private func quickStatsRow(_ vendor: User) -> some View {
        HStack(spacing: 0) {
            if let years = vendor.yearsInBusiness {
                statItem(value: "\(years)", label: years == 1 ? "Year" : "Years", icon: "clock.fill")
            }
            
            if let photos = vendor.portfolioUrls, !photos.isEmpty {
                if vendor.yearsInBusiness != nil {
                    Divider()
                        .frame(height: 40)
                }
                statItem(value: "\(photos.count)", label: "Photos", icon: "photo.fill")
            }
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "8B5CF6"))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.custom("Spectral-Bold", size: 18))
                Text(label)
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Bio Section
    
    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ABOUT")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)
            
            Text(bio)
                .font(.custom("Spectral-Regular", size: 15))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Services Section
    
    private func servicesSection(_ services: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SERVICES")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)
            
            VendorProfileFlowLayout(spacing: 8) {
                ForEach(services, id: \.self) { service in
                    Text(service.capitalized)
                        .font(.custom("Spectral-Medium", size: 13))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .padding(.horizontal, 14)
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
    
    // MARK: - Links Section
    
    private func hasLinks(_ vendor: User) -> Bool {
        vendor.websiteUrlParsed != nil || vendor.instagramUrl != nil
    }
    
    private func linksSection(_ vendor: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LINKS")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)
            
            VStack(spacing: 10) {
                if let websiteUrl = vendor.websiteUrlParsed {
                    Link(destination: websiteUrl) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(Color(hex: "3B82F6"))
                                .frame(width: 24)
                            Text(vendor.websiteUrl ?? "Website")
                                .font(.custom("Spectral-Regular", size: 14))
                                .foregroundColor(Color(hex: "3B82F6"))
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(12)
                        .background(Color(hex: "3B82F6").opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                if let instagramUrl = vendor.instagramUrl {
                    Link(destination: instagramUrl) {
                        HStack {
                            Image(systemName: "camera")
                                .foregroundColor(Color(hex: "E1306C"))
                                .frame(width: 24)
                            Text("@\(vendor.instagramHandle ?? "")")
                                .font(.custom("Spectral-Regular", size: 14))
                                .foregroundColor(Color(hex: "E1306C"))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(12)
                        .background(Color(hex: "E1306C").opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Portfolio Section (Masonry Grid)
    
    private func portfolioSection(_ photos: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PORTFOLIO")
                    .font(.custom("Spectral-Bold", size: 12))
                    .foregroundColor(.gray)
                
                Text("Tap to view")
                    .font(.custom("Spectral-Regular", size: 11))
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            MasonryGrid(photos: photos) { index in
                selectedPhotoIndex = index
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // MARK: - Action Buttons
    
    private func actionButtons(_ vendor: User) -> some View {
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
            
            NavigationLink(destination: ChatView(partner: MessageUser(id: vendor.id, name: vendor.name, userType: vendor.userType.rawValue))) {
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
            
            if let phone = vendor.phoneNumber, !phone.isEmpty {
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
}

// MARK: - Masonry Grid

struct MasonryGrid: View {
    let photos: [String]
    let onTap: (Int) -> Void
    
    private let spacing: CGFloat = 8
    
    // Varying heights for visual interest
    private func getHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [140, 180, 160, 200, 150, 170, 190, 145]
        return heights[index % heights.count]
    }
    
    // Split photos into left/right columns
    private var leftColumnPhotos: [(index: Int, url: String)] {
        photos.enumerated().filter { $0.offset % 2 == 0 }.map { ($0.offset, $0.element) }
    }
    
    private var rightColumnPhotos: [(index: Int, url: String)] {
        photos.enumerated().filter { $0.offset % 2 == 1 }.map { ($0.offset, $0.element) }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            // Left column (even indices)
            VStack(spacing: spacing) {
                ForEach(leftColumnPhotos, id: \.index) { item in
                    MasonryPhotoCell(
                        urlString: item.url,
                        height: getHeight(for: item.index)
                    ) {
                        onTap(item.index)
                    }
                }
            }
            
            // Right column (odd indices)
            VStack(spacing: spacing) {
                ForEach(rightColumnPhotos, id: \.index) { item in
                    MasonryPhotoCell(
                        urlString: item.url,
                        height: getHeight(for: item.index)
                    ) {
                        onTap(item.index)
                    }
                }
            }
        }
    }
}

struct MasonryPhotoCell: View {
    let urlString: String
    let height: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: height)
                            .clipped()
                    case .failure(_):
                        Color.gray.opacity(0.2)
                            .frame(height: height)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    case .empty:
                        Color.gray.opacity(0.1)
                            .frame(height: height)
                            .overlay(ProgressView())
                    @unknown default:
                        Color.gray.opacity(0.1)
                            .frame(height: height)
                    }
                }
                .cornerRadius(12)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photo Gallery (Fullscreen Viewer)

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

struct PhotoGalleryView: View {
    let photos: [String]
    let initialIndex: Int
    
    @State private var currentIndex: Int
    @Environment(\.dismiss) var dismiss
    @GestureState private var dragOffset: CGFloat = 0
    
    init(photos: [String], initialIndex: Int) {
        self.photos = photos
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Photo
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, urlString in
                    ZoomablePhotoView(urlString: urlString)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Overlay controls
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.custom("Spectral-Bold", size: 18))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(photos.count)")
                        .font(.custom("Spectral-Medium", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(16)
                }
                .padding()
                
                Spacer()
                
                // Bottom indicator dots
                if photos.count > 1 && photos.count <= 10 {
                    HStack(spacing: 6) {
                        ForEach(0..<photos.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .statusBarHidden()
    }
}

struct ZoomablePhotoView: View {
    let urlString: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1), 4)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if scale < 1 {
                                            withAnimation { scale = 1 }
                                        }
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                        if scale <= 1 {
                                            withAnimation {
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if scale > 1 {
                                        scale = 1
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2
                                    }
                                }
                            }
                    case .failure(_):
                        Image(systemName: "photo")
                            .font(.custom("Spectral-Regular", size: 50))
                            .foregroundColor(.gray)
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

// MARK: - View Model

@MainActor
class VendorProfileViewModel: ObservableObject {
    @Published var vendor: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadVendor(id: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            vendor = try await APIService.shared.getVendorProfile(vendorId: id)
        } catch {
            errorMessage = "Failed to load vendor profile"
            print("❌ Error loading vendor: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Invite Sheet

struct VendorInviteToRFPSheet: View {
    let vendorId: Int
    let vendorName: String
    @Environment(\.dismiss) var dismiss
    @State private var rfps: [RFP] = []
    @State private var isLoading = true
    @State private var selectedRFP: RFP?
    @State private var isInviting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if rfps.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.custom("Spectral-Regular", size: 40))
                            .foregroundColor(.gray)
                        Text("No open RFPs")
                            .font(.custom("Spectral-Medium", size: 16))
                        Text("Create an RFP first to invite vendors")
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.gray)
                    }
                } else {
                    List(rfps) { rfp in
                        Button {
                            selectedRFP = rfp
                            Task { await inviteVendor(to: rfp) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rfp.title)
                                        .font(.custom("Spectral-Medium", size: 15))
                                        .foregroundColor(.black)
                                    if let budget = rfp.budget {
                                        Text("$\(budget / 100)")
                                            .font(.custom("Spectral-Regular", size: 13))
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                if isInviting && selectedRFP?.id == rfp.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .listRowBackground(Color.white)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Invite to RFP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Invited!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(vendorName) has been invited to bid on your RFP.")
            }
        }
        .task {
            await loadRFPs()
        }
    }
    
    private func loadRFPs() async {
        do {
            rfps = try await APIService.shared.getMyRFPs()
            rfps = rfps.filter { $0.status == .open }
        } catch {
            print("❌ Error loading RFPs: \(error)")
        }
        isLoading = false
    }
    
    private func inviteVendor(to rfp: RFP) async {
        isInviting = true
        do {
            try await APIService.shared.inviteVendorToRFP(rfpId: rfp.id, vendorId: vendorId)
            showSuccess = true
        } catch {
            print("❌ Error inviting vendor: \(error)")
        }
        isInviting = false
    }
}

// MARK: - Flow Layout (local to this file)

struct VendorProfileFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

#Preview {
    NavigationStack {
        VendorProfileView(vendorId: 1)
    }
}

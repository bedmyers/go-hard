//
//  ProfileView.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    
                    accountSection
                    
                    settingsSection
                    
                    supportSection
                    
                    logoutButton
                    
                    appVersion
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(Color("Background"))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .confirmationDialog("Log Out", isPresented: $showLogoutConfirm) {
            Button("Log Out", role: .destructive) {
                appState.logout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccountConfirm) {
            Button("Delete Account", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your profile, personal info and messages you've sent will be permanently deleted and you'll be logged out. Records of past payments are kept for the other party. This can't be undone.")
        }
        .alert(
            "Couldn't Delete Account",
            isPresented: Binding(get: { deleteAccountError != nil }, set: { if !$0 { deleteAccountError = nil } }),
            presenting: deleteAccountError
        ) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Deleting account…")
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(16)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            VendorEditProfileView()
        }
    }
    
    // MARK: - Delete Account

    private func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            _ = try await APIService.shared.deleteAccount()
            appState.logout()
        } catch {
            // e.g. "You have 1 escrow still holding money..."
            deleteAccountError = error.localizedDescription
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(initials)
                    .font(.custom("DelaGothicOne-Regular", size: 36))
                    .foregroundColor(.black)
            }
            
            VStack(spacing: 6) {
                Text(appState.currentUser?.name ?? "User")
                    .font(.custom("DelaGothicOne-Regular", size: 24))
                
                Text(appState.currentUser?.email ?? "")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                
                UserTypeBadge(userType: appState.currentUser?.userType ?? .customer)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var initials: String {
        guard let name = appState.currentUser?.name else { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
    
    // MARK: - Account Section

    private var isVendor: Bool {
        appState.currentUser?.userType == .vendor || appState.currentUser?.userType == .both
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Account")

            VStack(spacing: 0) {
                ProfileRow(icon: "person.fill", title: "Edit Profile", showChevron: true) {
                    showEditProfile = true
                }

                Divider().padding(.leading, 52)

                ProfileRow(icon: "creditcard.fill", title: "Payment Methods", showChevron: true) {
                    // TODO: Payment methods
                }

                if isVendor {
                    Divider().padding(.leading, 52)

                    NavigationLink {
                        VendorOnboardingView()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "FFD700"))
                                .frame(width: 24)

                            Text("Bank Account")
                                .font(.custom("Spectral-Regular", size: 15))
                                .foregroundColor(.black)

                            Spacer()

                            if appState.currentUser?.stripeAccountId != nil {
                                Text("Connected")
                                    .font(.custom("Spectral-Medium", size: 12))
                                    .foregroundColor(Color(hex: "22C55E"))
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }

                Divider().padding(.leading, 52)

                ProfileRow(icon: "bell.fill", title: "Notifications", showChevron: true) {
                    // TODO: Notifications
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Settings")
            
            VStack(spacing: 0) {
                ProfileRow(icon: "lock.fill", title: "Security", showChevron: true) {
                    // TODO: Security settings
                }
                
                Divider().padding(.leading, 52)
                
                ProfileRow(icon: "hand.raised.fill", title: "Privacy", showChevron: true) {
                    // TODO: Privacy settings
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Support")
            
            VStack(spacing: 0) {
                ProfileRow(icon: "questionmark.circle.fill", title: "Help Center", showChevron: true) {
                    if let url = URL(string: "https://gohard.app/help") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Divider().padding(.leading, 52)
                
                ProfileRow(icon: "envelope.fill", title: "Contact Us", showChevron: true) {
                    if let url = URL(string: "mailto:support@gohard.app") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Divider().padding(.leading, 52)
                
                ProfileRow(icon: "doc.text.fill", title: "Terms of Service", showChevron: true) {
                    if let url = URL(string: "https://gohard.app/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Divider().padding(.leading, 52)
                
                ProfileRow(icon: "shield.fill", title: "Privacy Policy", showChevron: true) {
                    if let url = URL(string: "https://gohard.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Logout Button
    
    private var logoutButton: some View {
        VStack(spacing: 12) {
            Button {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                    Text("Log Out")
                        .font(.custom("Spectral-Bold", size: 16))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            
            Button {
                showDeleteAccountConfirm = true
            } label: {
                Text("Delete Account")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - App Version
    
    private var appVersion: some View {
        VStack(spacing: 4) {
            Text("GO HARD")
                .font(.custom("DelaGothicOne-Regular", size: 12))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Version 1.0.0 (1)")
                .font(.custom("Spectral-Regular", size: 11))
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding(.top, 20)
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.custom("Spectral-Bold", size: 12))
            .foregroundColor(.gray)
            .padding(.leading, 4)
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let icon: String
    let title: String
    var showChevron: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "FFD700"))
                    .frame(width: 24)

                Text(title)
                    .font(.custom("Spectral-Regular", size: 15))
                    .foregroundColor(.black)

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - User Type Badge

private struct UserTypeBadge: View {
    let userType: User.UserType
    
    var body: some View {
        Text(userType == .customer ? "CUSTOMER" : "VENDOR")
            .font(.custom("Spectral-Bold", size: 10))
            .foregroundColor(userType == .customer ? Color(hex: "8B5CF6") : Color(hex: "22C55E"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                (userType == .customer ? Color(hex: "8B5CF6") : Color(hex: "22C55E")).opacity(0.15)
            )
            .cornerRadius(4)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AppState())
}

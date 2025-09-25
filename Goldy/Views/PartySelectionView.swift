//
//  PartySelectionView.swift
//  Goldy
//
//  Created by Blair Myers on 9/17/25.
//

import SwiftUI

struct PartySelectionView: View {
    @Binding var selectedUsers: [User]
    @Binding var selectedSellerId: Int
    let currentUserId: Int
    
    @StateObject private var userSearchVM = UserSearchViewModel()
    @State private var showUserSearch = false
    
    var hasError: Bool {
        selectedUsers.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            EscrowSectionHeader(title: "ADD A PARTY", isRequired: true)

            HStack(spacing: 16) {
                // Display selected users
                ForEach(selectedUsers, id: \.id) { user in
                    UserAvatarView(user: user) {
                        removeUser(user)
                    }
                }

                // Add party button
                Button(action: { showUserSearch = true }) {
                    Image(systemName: selectedUsers.isEmpty ? "plus.circle" : "plus")
                        .font(.system(size: selectedUsers.isEmpty ? 28 : 20, weight: .medium))
                        .foregroundColor(selectedUsers.isEmpty ? .blue : .secondary)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(selectedUsers.isEmpty ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .overlay(
                                    Circle()
                                        .stroke(selectedUsers.isEmpty ? Color.blue : Color(.systemGray4), lineWidth: 1.5)
                                )
                        )
                }
                .scaleEffect(selectedUsers.isEmpty ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedUsers.isEmpty)
            }
            
            // Show selected party info or empty state
            if selectedUsers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No party selected")
                        .font(.custom("IBMPlexMono-Regular", size: 12))
                        .foregroundColor(.secondary)
                    
                    if hasError {
                        ValidationErrorText(message: "Please select at least one party member")
                    }
                }
            } else {
                Text("Selected: \(selectedUsers.map { $0.name }.joined(separator: ", "))")
                    .font(.custom("IBMPlexMono-Regular", size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
        }
        .sheet(isPresented: $showUserSearch) {
            UserSearchSheetView(
                viewModel: userSearchVM,
                currentUserId: currentUserId
            ) { user in
                selectedUsers = [user]
                selectedSellerId = user.id
            }
        }
    }
    
    private func removeUser(_ user: User) {
        selectedUsers.removeAll { $0.id == user.id }
        if selectedSellerId == user.id {
            selectedSellerId = 0
        }
    }
}

private struct UserAvatarView: View {
    let user: User
    let onRemove: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Main avatar
            Text(initials(for: user.name))
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                )
                .scaleEffect(isHovered ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            
            // Remove button - positioned outside the circle
            VStack {
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .frame(width: 18, height: 18)
                            )
                    }
                    .offset(x: 8, y: -8)
                }
                Spacer()
            }
            .frame(width: 50, height: 50)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func initials(for name: String) -> String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }
}

/*#Preview {
    @State var selectedUsers: [User] = []
    @State var selectedSellerId: Int = 0
    
    return VStack(spacing: 30) {
        // Empty state
        PartySelectionView(
            selectedUsers: $selectedUsers,
            selectedSellerId: $selectedSellerId,
            currentUserId: 1
        )
        
        // With users selected
        PartySelectionView(
            selectedUsers: .constant([
                User(id: 1, name: "John Doe", avatarImageName: nil),
                User(id: 2, name: "Jane Smith", avatarImageName: nil)
            ]),
            selectedSellerId: .constant(1),
            currentUserId: 1
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}*/

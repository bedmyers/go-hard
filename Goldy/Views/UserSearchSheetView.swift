//
//  UserSearchSheetView.swift
//  Goldy
//
//  Created by Blair Myers on 7/8/25.
//

import Foundation
import SwiftUI

struct UserSearchSheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: UserSearchViewModel
    var currentUserId: Int
    var onSelect: (User) -> Void

    @State private var query = ""
    @AppStorage("authToken") private var authToken: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchHeaderSection
                
                if query.isEmpty {
                    emptySearchState
                } else if viewModel.isLoading {
                    loadingState
                } else if viewModel.results.isEmpty {
                    noResultsState
                } else {
                    searchResults
                }
            }
            .background(Color(red: 0.97, green: 0.93, blue: 0.85))
            .navigationTitle("Add a Party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchHeaderSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.black)
                    .opacity(0.6)
                    .font(.system(size: 16))
                
                TextField("Search name or email", text: $query)
                    .font(.custom("IBMPlexMono-Regular", size: 16))
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.black)
                            .opacity(0.6)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            if !query.isEmpty && !viewModel.results.isEmpty {
                Text("\(filteredResults.count) result\(filteredResults.count == 1 ? "" : "s") found")
                    .font(.custom("IBMPlexMono-Regular", size: 12))
                    .foregroundColor(.black)
                    .opacity(0.6)
            }
        }
        .padding(20)
        .onChange(of: query) { newValue in
            if !newValue.isEmpty {
                viewModel.searchUsers(query: newValue, token: authToken)
            }
        }
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.black)
                .opacity(0.4)
            
            VStack(spacing: 8) {
                Text("ADD A PARTY")
                    .font(.custom("DelaGothicOne-Regular", size: 20))
                    .foregroundColor(.black)
                
                Text("Search for people to add to your escrow by name or email address")
                    .font(.custom("IBMPlexMono-Regular", size: 14))
                    .foregroundColor(.black)
                    .opacity(0.6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(.black)
            
            Text("Searching...")
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .opacity(0.6)
            
            Spacer()
        }
    }
    
    private var noResultsState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.black)
                .opacity(0.4)
            
            VStack(spacing: 8) {
                Text("NO RESULTS FOUND")
                    .font(.custom("DelaGothicOne-Regular", size: 18))
                    .foregroundColor(.black)
                
                Text("Try searching with a different name or email address")
                    .font(.custom("IBMPlexMono-Regular", size: 14))
                    .foregroundColor(.black)
                    .opacity(0.6)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredResults, id: \.id) { user in
                    UserResultRow(user: user) {
                        onSelect(user)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var filteredResults: [User] {
        viewModel.results.filter { $0.id != currentUserId }
    }
    
    private func onChange(of query: String, newValue: String) {
        if !newValue.isEmpty {
            viewModel.searchUsers(query: newValue, token: authToken)
        }
    }
}

// MARK: - Supporting Views

private struct UserResultRow: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color("ActiveColor"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(initials(for: user.name))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                            .foregroundColor(.black)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(user.email)
                        .font(.custom("IBMPlexMono-Regular", size: 12))
                        .foregroundColor(.black)
                        .opacity(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func initials(for name: String) -> String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }
}

#Preview {
    UserSearchSheetView(
        viewModel: UserSearchViewModel(),
        currentUserId: 1
    ) { user in
        print("Selected user: \(user.name)")
    }
}

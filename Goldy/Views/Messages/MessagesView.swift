//
//  Messages.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.conversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: MessageUser.self) { partner in
                ChatView(partner: partner)
            }
        }
        .task {
            await viewModel.loadConversations()
        }
        .refreshable {
            await viewModel.loadConversations()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.custom("Spectral-Regular", size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Messages Yet")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Your conversations will appear here")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(value: conversation.partner) {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.leading, 76)
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding()
        }
    }
}

// MARK: - Conversation Row

private struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "FFD700").opacity(0.2))
                    .frame(width: 52, height: 52)
                
                Text(initials)
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(Color(hex: "B8860B"))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.partner.name)
                        .font(.custom("Spectral-Bold", size: 16))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(conversation.lastMessage.timeDisplay)
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(conversation.lastMessage.content)
                        .font(.custom("Spectral-Regular", size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.custom("Spectral-Bold", size: 11))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Color(hex: "FF6B35"))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var initials: String {
        let parts = conversation.partner.name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(conversation.partner.name.prefix(2)).uppercased()
    }
}

// MARK: - View Model

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = true
    
    func loadConversations() async {
        do {
            conversations = try await APIService.shared.getConversations()
        } catch {
            print("❌ Error loading conversations: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Make MessageUser Hashable for navigation

extension MessageUser: Hashable {
    static func == (lhs: MessageUser, rhs: MessageUser) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    MessagesView()
}

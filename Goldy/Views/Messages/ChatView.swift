//
//  ChatView.swift
//  Goldy
//
//  Created by Blair Myers on 12/7/25.
//

import SwiftUI

struct ChatView: View {
    let partner: MessageUser
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    init(partner: MessageUser) {
        self.partner = partner
        _viewModel = StateObject(wrappedValue: ChatViewModel(partnerId: partner.id))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Input bar
            inputBar
        }
        .background(Color(hex: "F5F1E8"))
        .navigationTitle(partner.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(partner.name)
                        .font(.custom("Spectral-Bold", size: 16))
                    if let userType = partner.userType {
                        Text(userType.capitalized)
                            .font(.custom("Spectral-Regular", size: 11))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .task {
            await viewModel.loadMessages()
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $viewModel.newMessage, axis: .vertical)
                .font(.custom("Spectral-Regular", size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isInputFocused)
            
            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.custom("Spectral-Regular", size: 18))
                    .foregroundColor(viewModel.canSend ? .black : .gray)
                    .frame(width: 44, height: 44)
                    .background(viewModel.canSend ? Color(hex: "FFD700") : Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
            .disabled(!viewModel.canSend || viewModel.isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.custom("Spectral-Regular", size: 15))
                    .foregroundColor(message.isFromCurrentUser ? .white : .black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromCurrentUser
                            ? Color.black
                            : Color.white
                    )
                    .cornerRadius(18)
                    .cornerRadius(4, corners: message.isFromCurrentUser ? .bottomRight : .bottomLeft)
                
                Text(message.timeDisplay)
                    .font(.custom("Spectral-Regular", size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Model

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessage = ""
    @Published var isSending = false
    @Published var isLoading = true
    
    private let partnerId: Int
    private var pollingTask: Task<Void, Never>?
    
    var canSend: Bool {
        !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(partnerId: Int) {
        self.partnerId = partnerId
    }
    
    func loadMessages() async {
        do {
            messages = try await APIService.shared.getMessages(with: partnerId)
        } catch {
            print("❌ Error loading messages: \(error)")
        }
        isLoading = false
    }
    
    func sendMessage() async {
        let content = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        isSending = true
        newMessage = ""
        
        do {
            let message = try await APIService.shared.sendMessage(to: partnerId, content: content)
            messages.append(message)
        } catch {
            print("❌ Error sending message: \(error)")
            newMessage = content // Restore on failure
        }
        
        isSending = false
    }
    
    func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if !Task.isCancelled {
                    await refreshMessages()
                }
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    private func refreshMessages() async {
        do {
            let newMessages = try await APIService.shared.getMessages(with: partnerId)
            if newMessages.count != messages.count {
                messages = newMessages
            }
        } catch {
            print("❌ Error refreshing messages: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(partner: MessageUser(id: 1, name: "Sarah Chen Photography", userType: "VENDOR"))
    }
}

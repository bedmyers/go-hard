//
//  FillOutEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 6/6/25.
//

import SwiftUI

struct FillOutEscrowView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: EscrowViewModel
    var onComplete: (() -> Void)? = nil

    @State private var purposeText: String = ""
    @State private var escrowFund = EscrowFund(text: "", amount: nil)
    @State private var releaseFunds: [EscrowFund] = Array(repeating: EscrowFund(text: "", amount: nil), count: 3)
    @State private var cancellationPolicyText: String = ""
    @State private var selectedSellerId: Int = 0
    @State private var editableEscrowName: String = ""
    @State private var selectedUsers: [User] = []
    @State private var isLoading = false
    @State private var showValidationErrors = false
    
    var escrowName: String
    var parties: [String]

    @AppStorage("userId") var userId: Int = 0
    @AppStorage("authToken") var authToken: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                headerSection
                
                // Form sections
                VStack(spacing: 32) {
                    escrowNameSection
                    partySelectionSection
                    termsConditionsSection
                    purposeSection
                    escrowFundsSection
                    releaseConditionsSection
                    cancellationPolicySection
                    signedSection
                    submitButton
                    saveForLaterButton
                }
            }
            .padding(24)
        }
        .background(Color(red: 0.97, green: 0.93, blue: 0.85).ignoresSafeArea())
        .onAppear {
            editableEscrowName = escrowName
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CREATE AN ESCROW")
                    .font(.custom("DelaGothicOne-Regular", size: 30))
                    .foregroundColor(.black)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            
            Text("Fill out the details below to create your escrow agreement")
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .opacity(0.7)
        }
    }
    
    private var escrowNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text("ESCROW NAME")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.black)
                
                Text("*")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.red)
            }
            
            TextField("Start typing...", text: $editableEscrowName)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(validationBorder(isEmpty: editableEscrowName.isEmpty), lineWidth: 1.5)
                )
            
            if showValidationErrors && editableEscrowName.isEmpty {
                ValidationMessage(text: "Escrow name is required")
            }
        }
    }
    
    private var partySelectionSection: some View {
        PartySelectionView(
            selectedUsers: $selectedUsers,
            selectedSellerId: $selectedSellerId,
            currentUserId: userId
        )
    }
    
    private var termsConditionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ADD TERMS & CONDITIONS")
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(.black)
            
            HStack(spacing: 12) {
                TermsButton(
                    icon: "doc.badge.plus",
                    title: "UPLOAD",
                    subtitle: "From files",
                    isDisabled: true,
                    action: {}
                )
                
                TermsButton(
                    icon: "doc.text",
                    title: "CREATE",
                    subtitle: "From scratch",
                    action: {}
                )
            }
        }
    }
    
    private var purposeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PURPOSE OF THE ESCROW")
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(.black)
            
            TextField("Describe the purpose of this escrow...", text: $purposeText, axis: .vertical)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .frame(minHeight: 100, alignment: .topLeading)
        }
    }
    
    private var escrowFundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text("ESCROWED FUNDS")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.black)
                
                Text("*")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.red)
            }
            
            EscrowFundCard(fund: $escrowFund)
            
            if showValidationErrors && (escrowFund.amount == nil || escrowFund.amount! <= 0) {
                ValidationMessage(text: "Please enter a valid amount greater than $0")
            }
        }
    }
    
    private var releaseConditionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONDITIONS FOR RELEASE")
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ForEach(releaseFunds.indices, id: \.self) { i in
                    EscrowFundCard(fund: $releaseFunds[i])
                }
            }
            
            Text("Define the conditions under which funds will be released")
                .font(.custom("IBMPlexMono-Regular", size: 12))
                .foregroundColor(.black)
                .opacity(0.6)
        }
    }
    
    private var cancellationPolicySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CANCELLATION & REFUND POLICY")
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(.black)
            
            TextField("Describe your cancellation and refund policy...", text: $cancellationPolicyText, axis: .vertical)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .frame(minHeight: 100, alignment: .topLeading)
        }
    }
    
    private var signedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SIGNATORIES")
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(.black)
            
            HStack(spacing: 20) {
                // Current user (buyer)
                SignatoryView(
                    title: "YOU",
                    subtitle: "Buyer",
                    isCurrentUser: true
                )
                
                // Selected party (seller)
                if let selectedUser = selectedUsers.first {
                    SignatoryView(
                        initials: initials(for: selectedUser.name),
                        subtitle: "Seller"
                    )
                } else {
                    SignatoryView(
                        subtitle: "Add Party",
                        isEmpty: true
                    )
                }
            }
            
            StatusIndicator(isValid: isFormValid)
        }
    }
    
    private var submitButton: some View {
        Button(action: submitEscrow) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                }
                
                Text(isLoading ? "CREATING..." : "SAVE & SHARE")
                    .font(.custom("DaysOne-Regular", size: 16))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(buttonBackground)
            )
            .shadow(color: .black.opacity(isFormValid ? 0.1 : 0), radius: 4, y: 2)
        }
        .disabled(isLoading || !isFormValid)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
    }
    
    private var saveForLaterButton: some View {
        HStack {
            Spacer()
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 12))
                    Text("SAVE FOR LATER")
                        .font(.custom("DelaGothicOne-Regular", size: 12))
                }
                .foregroundColor(.black)
                .opacity(0.7)
            }
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // MARK: - Supporting Views
    
    private struct ValidationMessage: View {
        let text: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                
                Text(text)
                    .font(.custom("IBMPlexMono-Regular", size: 12))
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private struct TermsButton: View {
        let icon: String
        let title: String
        let subtitle: String
        var isDisabled: Bool = false
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .opacity(isDisabled ? 0.4 : 1.0)
                    
                    VStack(spacing: 2) {
                        Text(title)
                            .font(.custom("DelaGothicOne-Regular", size: 13))
                            .foregroundColor(.black)
                        
                        Text(subtitle)
                            .font(.custom("IBMPlexMono-Regular", size: 10))
                            .foregroundColor(.black)
                            .opacity(0.6)
                    }
                    
                    if isDisabled {
                        Text("SOON")
                            .font(.custom("DelaGothicOne-Regular", size: 8))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding()
                .background(Color("Button"))
                .cornerRadius(12)
                .opacity(isDisabled ? 0.7 : 1.0)
            }
            .disabled(isDisabled)
        }
    }
    
    private struct SignatoryView: View {
        var title: String? = nil
        var initials: String? = nil
        let subtitle: String
        var isCurrentUser: Bool = false
        var isEmpty: Bool = false
        
        var body: some View {
            VStack(spacing: 8) {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Group {
                            if isEmpty {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.black)
                                    .opacity(0.4)
                            } else if let title = title {
                                Text(title)
                                    .font(.custom("DelaGothicOne-Regular", size: 12))
                                    .foregroundColor(.black)
                            } else if let initials = initials {
                                Text(initials)
                                    .font(.custom("DelaGothicOne-Regular", size: 16))
                                    .foregroundColor(.black)
                            }
                        }
                    )
                
                Text(subtitle)
                    .font(.custom("DaysOne-Regular", size: 10))
                    .foregroundColor(.black)
                    .opacity(0.6)
            }
        }
        
        private var backgroundColor: Color {
            if isEmpty {
                return Color.white.opacity(0.8)
            } else {
                return Color("ActiveColor")
            }
        }
    }
    
    private struct StatusIndicator: View {
        let isValid: Bool
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: isValid ? "checkmark.circle.fill" : "clock.circle")
                    .font(.system(size: 14))
                    .foregroundColor(isValid ? .green : .orange)
                
                Text(isValid ? "Ready to create" : "Complete required fields")
                    .font(.custom("DaysOne-Regular", size: 12))
                    .foregroundColor(.black)
                    .opacity(0.6)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Helper Properties
    
    private var isFormValid: Bool {
        !editableEscrowName.isEmpty &&
        selectedSellerId != 0 &&
        escrowFund.amount != nil &&
        escrowFund.amount! > 0
    }
    
    private var buttonBackground: Color {
        if isLoading || !isFormValid {
            return Color.black.opacity(0.3)
        } else {
            return Color.black
        }
    }
    
    private func validationBorder(isEmpty: Bool) -> Color {
        if showValidationErrors && isEmpty {
            return Color.red
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    // MARK: - Actions
    
    private func submitEscrow() {
        if !isFormValid {
            showValidationErrors = true
            return
        }
        
        isLoading = true
        
        let totalCents = Int(((escrowFund.amount ?? 0) * 100).rounded())
        let milestonePayload: [[String: Any]] = releaseFunds
            .compactMap { $0.amount }
            .map { ["amountCents": Int(($0 * 100).rounded())] }

        let payload: [String: Any] = [
            "title": editableEscrowName,
            "sellerId": selectedSellerId,
            "amountCents": totalCents,
            "status": "PENDING",
            "milestones": milestonePayload
        ]

        guard let url = URL(string: "https://go-hard-backend-production.up.railway.app/escrow/create"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    return
                }
                
                guard let data = data else { return }

                do {
                    let dto = try JSONDecoder().decode(EscrowDTO.self, from: data)
                    let project = dto.toProject()
                    
                    viewModel.addEscrow(project)
                    
                    if let onComplete = onComplete {
                        onComplete()
                    } else {
                        dismiss()
                    }
                } catch {
                    // Handle error
                }
            }
        }.resume()
    }
    
    private func initials(for name: String) -> String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }
}

#Preview {
    FillOutEscrowView(
        viewModel: EscrowViewModel(),
        escrowName: "Sample Escrow",
        parties: ["profile1", "profile2"]
    )
}

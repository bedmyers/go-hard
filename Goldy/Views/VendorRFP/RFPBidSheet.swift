//
//  RFPBidSheet.swift
//  Goldy
//
//  Sheet for a vendor to submit a bid on an RFP
//

import SwiftUI

struct RFPBidSheet: View {
    let rfp: RFP
    let onSubmitted: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    @State private var proposal = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    
    var isValid: Bool {
        !amount.isEmpty &&
        Int(amount.replacingOccurrences(of: ",", with: "")) != nil &&
        !proposal.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var amountCents: Int {
        let cleaned = amount.replacingOccurrences(of: ",", with: "")
        return (Int(cleaned) ?? 0) * 100
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // RFP Summary
                    rfpSummary
                    
                    // Bid form
                    bidForm
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Submit Bid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                submitButton
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
    }
    
    // MARK: - RFP Summary
    
    private var rfpSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(rfp.title)
                .font(.custom("DelaGothicOne-Regular", size: 18))
            
            Text(rfp.description)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("Budget: \(rfp.budgetFormatted)")
                        .font(.custom("Spectral-Medium", size: 13))
                }
                
                if let deadline = rfp.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(Color(hex: "FF6B35"))
                        Text(deadline.formatted(date: .abbreviated, time: .omitted))
                            .font(.custom("Spectral-Medium", size: 13))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    // MARK: - Bid Form
    
    private var bidForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("YOUR BID")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)
            
            // Amount
            VStack(alignment: .leading, spacing: 6) {
                Text("Bid Amount")
                    .font(.custom("Spectral-Medium", size: 13))
                
                HStack {
                    Text("$")
                        .font(.custom("Spectral-Bold", size: 18))
                        .foregroundColor(.gray)
                    TextField("0", text: $amount)
                        .font(.custom("Spectral-Bold", size: 24))
                        .keyboardType(.numberPad)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                if rfp.budget != nil {
                    Text("Client budget: \(rfp.budgetFormatted)")
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // Proposal
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Proposal")
                    .font(.custom("Spectral-Medium", size: 13))
                
                TextEditor(text: $proposal)
                    .font(.custom("Spectral-Regular", size: 15))
                    .frame(minHeight: 150)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Text("Introduce yourself, describe your experience, and explain why you're a great fit")
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                Task { await submitBid() }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("SUBMIT BID")
                            .font(.custom("DelaGothicOne-Regular", size: 14))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "FFD700"))
                .cornerRadius(12)
            }
            .disabled(!isValid || isLoading)
            .opacity(isValid ? 1.0 : 0.5)
            .padding()
            .background(Color("Background"))
        }
    }
    
    // MARK: - Submit Bid
    
    private func submitBid() async {
        isLoading = true
        
        do {
            let body: [String: Any] = [
                "amount": amountCents,
                "proposal": proposal.trimmingCharacters(in: .whitespaces)
            ]
            
            let bid = try await APIService.shared.submitBid(rfpId: rfp.id, body: body)
            print("✅ Bid submitted: \(bid.id)")
            onSubmitted()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error submitting bid: \(error)")
        }
        
        isLoading = false
    }
}

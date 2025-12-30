//
//  VendorRFPBrowseView.swift
//  Goldy
//
//  Created by Blair Myers on 11/30/25.
//

import SwiftUI

struct VendorRFPBrowseView: View {
    @State private var rfps: [RFP] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedRFP: RFP?
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if rfps.isEmpty {
                emptyState
            } else {
                rfpList
            }
        }
        .navigationTitle("Find Work")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadRFPs()
        }
        .refreshable {
            await loadRFPs()
        }
        .sheet(item: $selectedRFP) { rfp in
            RFPBidSheet(rfp: rfp) {
                // On bid submitted, refresh and close
                Task { await loadRFPs() }
                selectedRFP = nil
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("No Open Requests")
                .font(.custom("DelaGothicOne-Regular", size: 20))
            
            Text("Check back soon - couples are posting new requests all the time")
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - RFP List
    
    private var rfpList: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(rfps.count) open request\(rfps.count == 1 ? "" : "s")")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 16) {
                    ForEach(rfps) { rfp in
                        OpenRFPCard(rfp: rfp) {
                            selectedRFP = rfp
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Load RFPs
    
    private func loadRFPs() async {
        do {
            rfps = try await APIService.shared.browseOpenRFPs()
            print("✅ Loaded \(rfps.count) open RFPs")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading RFPs: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Open RFP Card

private struct OpenRFPCard: View {
    let rfp: RFP
    let onBid: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(rfp.title)
                        .font(.custom("DelaGothicOne-Regular", size: 17))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 12) {
                        if let project = rfp.project {
                            Label(project.title, systemImage: "heart.fill")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.pink)
                        }
                        
                        Label("Posted \(rfp.createdAt.timeAgoDisplay())", systemImage: "clock")
                            .font(.custom("Spectral-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Budget badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(rfp.budgetFormatted)
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                        .foregroundColor(Color(hex: "22C55E"))
                    Text("budget")
                        .font(.custom("Spectral-Regular", size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            // Description
            Text(rfp.description)
                .font(.custom("Spectral-Regular", size: 14))
                .foregroundColor(.gray)
                .lineLimit(3)
            
            // Stats row
            HStack(spacing: 16) {
                if let deadline = rfp.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.custom("Spectral-Regular", size: 12))
                        Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            .font(.custom("Spectral-Regular", size: 12))
                    }
                    .foregroundColor(Color(hex: "FF6B35"))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.custom("Spectral-Regular", size: 12))
                    Text("\(rfp.bidCount) bid\(rfp.bidCount == 1 ? "" : "s")")
                        .font(.custom("Spectral-Regular", size: 12))
                }
                .foregroundColor(.gray)
                
                Spacer()
            }
            
            // Bid button
            Button(action: onBid) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("SUBMIT BID")
                        .font(.custom("DelaGothicOne-Regular", size: 13))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "FFD700"))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - RFP Bid Sheet

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
        .background(Color.white)
        .cornerRadius(12)
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
                
                if let budget = rfp.budget {
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

// MARK: - Preview

#Preview {
    NavigationStack {
        VendorRFPBrowseView()
    }
}

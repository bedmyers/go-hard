//
//  VendorDetailView.swift
//  Goldy
//
//  Created by Blair Myers on 11/25/25.
//

import SwiftUI

struct VendorDetailView: View {
    let projectVendor: ProjectVendor
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: VendorDetailViewModel
    
    init(projectVendor: ProjectVendor) {
        self.projectVendor = projectVendor
        _viewModel = StateObject(wrappedValue: VendorDetailViewModel(projectVendor: projectVendor))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                vendorHeader
                
                if viewModel.projectVendor.escrow != nil {
                    paymentProgressCard
                    milestonesSection
                }
                
                if viewModel.projectVendor.escrow == nil {
                    awaitingSetupCard
                }
                
                termsSection
                
                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color("Background"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showContactOptions = true
                } label: {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                }
            }
        }
        .confirmationDialog("Contact Vendor", isPresented: $viewModel.showContactOptions) {
            Button("Send Email") {
                if let url = URL(string: "mailto:\(viewModel.projectVendor.vendor.email)") {
                    UIApplication.shared.open(url)
                }
            }
            if let phone = viewModel.projectVendor.vendor.phoneNumber {
                Button("Call") {
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error)
        }
        .sheet(isPresented: $viewModel.showFundEscrow) {
            FundEscrowSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Vendor Header
    
    private var vendorHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: roleIcon)
                    .font(.system(size: 32))
                    .foregroundColor(roleColor)
            }
            
            VStack(spacing: 6) {
                Text(viewModel.projectVendor.role.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(roleColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(roleColor.opacity(0.15))
                    .cornerRadius(4)
                
                Text(viewModel.projectVendor.vendor.name)
                    .font(.custom("DelaGothicOne-Regular", size: 24))
                
                Text(viewModel.projectVendor.vendor.email)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            StatusBadge(status: viewModel.projectVendor.status)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Payment Progress
    
    private var paymentProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Progress")
                .font(.custom("DelaGothicOne-Regular", size: 18))
            
            let progress = viewModel.paymentProgress
            
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "BBF7D0"), Color(hex: "22C55E")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress.percentage, height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text(formatCurrency(progress.released))
                        .font(.system(size: 14, weight: .semibold))
                    +
                    Text(" of ")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    +
                    Text(formatCurrency(progress.total))
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()
                    
                    Text("\(Int(progress.percentage * 100))%")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                }
            }
            
            HStack(spacing: 0) {
                ProgressStat(label: "Released", value: formatCurrency(progress.released), color: Color(hex: "22C55E"))
                
                Divider().frame(height: 30)
                
                ProgressStat(label: "In Escrow", value: formatCurrency(progress.inEscrow), color: Color(hex: "F59E0B"))
                
                Divider().frame(height: 30)
                
                ProgressStat(label: "Pending", value: formatCurrency(progress.pending), color: Color.gray)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - Milestones
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .font(.custom("DelaGothicOne-Regular", size: 18))
                .padding(.horizontal)
            
            let milestones = viewModel.projectVendor.escrow?.milestones ?? []
            
            VStack(spacing: 12) {
                ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                    MilestoneCard(
                        milestone: milestone,
                        index: index,
                        isLast: index == milestones.count - 1,
                        escrowStatus: viewModel.projectVendor.escrow?.status ?? "PENDING",
                        onFund: {
                            viewModel.selectedMilestone = milestone
                            viewModel.showFundEscrow = true
                        },
                        onRelease: {
                            Task { await viewModel.releaseMilestone(milestone) }
                        },
                        isLoading: viewModel.isLoading
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Awaiting Setup
    
    private var awaitingSetupCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "F59E0B"))
            
            Text("Awaiting Vendor Setup")
                .font(.custom("DelaGothicOne-Regular", size: 18))
            
            Text("Once \(viewModel.projectVendor.vendor.name) accepts the invitation and completes their payment setup, you'll be able to fund the escrow.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "E9D5FF"))
                    .frame(width: 8, height: 8)
                Text("Invitation sent")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - Terms
    
    private var termsSection: some View {
        Button {
            viewModel.showTerms = true
        } label: {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.gray)
                
                Text("Terms & Conditions")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .sheet(isPresented: $viewModel.showTerms) {
            TermsSheetView(vendorName: viewModel.projectVendor.vendor.name, role: viewModel.projectVendor.role)
        }
    }
    
    // MARK: - Helpers
    
    private var roleIcon: String {
        let role = viewModel.projectVendor.role.lowercased()
        if role.contains("venue") { return "building.2.fill" }
        if role.contains("cater") || role.contains("food") { return "fork.knife" }
        if role.contains("photo") { return "camera.fill" }
        if role.contains("floral") || role.contains("flower") { return "leaf.fill" }
        if role.contains("music") || role.contains("dj") { return "music.note" }
        if role.contains("video") { return "video.fill" }
        if role.contains("planner") { return "calendar" }
        if role.contains("makeup") || role.contains("hair") { return "paintbrush.fill" }
        return "star.fill"
    }
    
    private var roleColor: Color {
        let role = viewModel.projectVendor.role.lowercased()
        if role.contains("venue") { return Color(hex: "8B5CF6") }
        if role.contains("cater") { return Color(hex: "22C55E") }
        if role.contains("photo") { return Color(hex: "FF6B35") }
        if role.contains("floral") { return Color(hex: "10B981") }
        if role.contains("music") || role.contains("dj") { return Color(hex: "F59E0B") }
        if role.contains("video") { return Color(hex: "EF4444") }
        return Color(hex: "6B7280")
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(displayStatus)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var displayStatus: String {
        switch status {
        case "PENDING", "INVITED": return "Invited"
        case "ACCEPTED": return "Accepted"
        case "PAID": return "Active"
        case "COMPLETED": return "Completed"
        default: return status
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "PENDING", "INVITED": return Color(hex: "8B5CF6")
        case "ACCEPTED": return Color(hex: "3B82F6")
        case "PAID": return Color(hex: "22C55E")
        case "COMPLETED": return Color(hex: "10B981")
        default: return .gray
        }
    }
}

// MARK: - Progress Stat

private struct ProgressStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Milestone Card

private struct MilestoneCard: View {
    let milestone: Milestone
    let index: Int
    let isLast: Bool
    let escrowStatus: String
    let onFund: () -> Void
    let onRelease: () -> Void
    let isLoading: Bool
    
    private var isFunded: Bool {
        escrowStatus == "AUTHORIZED" || escrowStatus == "COMPLETE"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(milestone.released ? Color(hex: "22C55E") : (isFunded ? Color(hex: "F59E0B") : Color.gray.opacity(0.3)))
                        .frame(width: 32, height: 32)
                    
                    if milestone.released {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isFunded ? .white : .gray)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(milestone.released ? Color(hex: "22C55E") : Color.gray.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(milestone.description ?? "Payment \(index + 1)")
                            .font(.system(size: 16, weight: .semibold))
                        
                        if let dueDate = milestone.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                                Text(dueDate, style: .date)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Text(formatCurrency(Double(milestone.amountCents) / 100.0))
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                }
                
                if let conditions = milestone.releaseConditions, !conditions.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 11))
                        Text(conditions)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)
                }
                
                milestoneAction
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }
    
    @ViewBuilder
    private var milestoneAction: some View {
        if milestone.released {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "22C55E"))
                Text("Released")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "22C55E"))
            }
        } else if isFunded {
            Button(action: onRelease) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("RELEASE PAYMENT")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "22C55E"))
                .cornerRadius(8)
            }
            .disabled(isLoading)
        } else if index == 0 {
            Button(action: onFund) {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text("FUND ESCROW")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.black)
                .cornerRadius(8)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                Text("Pending")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Fund Escrow Sheet

private struct FundEscrowSheet: View {
    @ObservedObject var viewModel: VendorDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "22C55E"))
                    
                    Text("Fund Escrow")
                        .font(.custom("DelaGothicOne-Regular", size: 24))
                    
                    Text("Securely hold funds until milestones are completed")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Vendor")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(viewModel.projectVendor.vendor.name)
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total Amount")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatCurrency(Double(viewModel.projectVendor.amountCents) / 100.0))
                            .font(.custom("DelaGothicOne-Regular", size: 20))
                    }
                }
                .padding()
                .background(Color(hex: "F9FAFB"))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.gray)
                        Text("•••• •••• •••• 4242")
                            .font(.system(size: 16))
                        Spacer()
                        Text("Change")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.fundEscrow()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "lock.fill")
                                Text("FUND \(formatCurrency(Double(viewModel.projectVendor.amountCents) / 100.0))")
                                    .font(.custom("DelaGothicOne-Regular", size: 14))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Funds held securely until you release them")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color("Background"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Terms Sheet

private struct TermsSheetView: View {
    let vendorName: String
    let role: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms & Conditions")
                        .font(.custom("DelaGothicOne-Regular", size: 24))
                    
                    Text("Agreement between you and \(vendorName)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    TermsBlock(title: "Service Description", content: "Vendor agrees to provide \(role.lowercased()) services as discussed and agreed upon between both parties.")
                    
                    TermsBlock(title: "Payment Terms", content: "Payment will be made through Go Hard's secure escrow system according to the milestone schedule defined in this agreement.")
                    
                    TermsBlock(title: "Cancellation Policy", content: "Cancellation terms vary based on timing. Full details were provided during agreement creation.")
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct TermsBlock: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VendorDetailView(
            projectVendor: ProjectVendor(
                id: 1,
                projectId: 1,
                vendorId: 1,
                vendor: User(id: 1, email: "vendor@test.com", name: "Bella Vista Events", userType: User.UserType.vendor),
                role: "Venue",
                description: nil,
                amountCents: 250000,
                dueDate: nil,
                status: "PENDING",
                escrow: Escrow(
                    id: 1,
                    projectVendorId: 1,
                    buyerId: 1,
                    sellerId: 2,
                    amountCents: 250000,
                    status: "PENDING",
                    stripePaymentIntentId: nil,
                    milestones: [
                        Milestone(id: 1, escrowId: 1, description: "Deposit", amountCents: 125000, releaseConditions: "Upon booking confirmation", dueDate: Date(), released: false, createdAt: Date(), updatedAt: Date()),
                        Milestone(id: 2, escrowId: 1, description: "Final Payment", amountCents: 125000, releaseConditions: "After event", dueDate: Date().addingTimeInterval(86400 * 30), released: false, createdAt: Date(), updatedAt: Date())
                    ],
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}

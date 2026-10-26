//
//  VendorAgreementView.swift
//  Goldy
//
//  Vendor's view of their agreement with a customer - shows only their details
//

import SwiftUI

struct VendorAgreementView: View {
    let project: Project
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    /// Kept locally so it can be refreshed after a refund or decline
    @State private var escrow: Escrow?
    @State private var showRefundConfirm = false
    @State private var showDeclineSheet = false
    @State private var errorMessage: String?
    @State private var noticeMessage: String?

    private let api = APIService.shared

    init(project: Project) {
        self.project = project
        _escrow = State(initialValue: project.myVendorRole?.escrow)
    }

    private var myRole: MyVendorRole? {
        project.myVendorRole
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                agreementDetailsCard

                if let escrow {
                    EscrowStatusBanner(escrow: escrow, perspective: .vendor, otherPartyName: project.customer.name)
                        .padding(.horizontal)

                    refundActions(escrow: escrow)
                    paymentStatusCard(escrow: escrow)
                    milestonesSection(escrow: escrow)
                }

                customerContactCard

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
        .background(Color("Background"))
        .navigationTitle("Agreement")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshEscrow() }
        .refreshable { await refreshEscrow() }
        .confirmationDialog("Refund Customer", isPresented: $showRefundConfirm) {
            Button("Refund \(formatCents(escrow?.unreleasedCents ?? 0))", role: .destructive) {
                Task { await refund() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\(formatCents(escrow?.unreleasedCents ?? 0)) still in escrow goes back to \(project.customer.name) and the booking is canceled. Payments already released stay with you. This can't be undone.")
        }
        .sheet(isPresented: $showDeclineSheet) {
            CancellationReasonSheet(
                title: "Decline Cancellation",
                message: "Go Hard will review the booking and decide what happens to the money still in escrow. Payouts stay paused until then.",
                placeholder: "Why should the booking stand?",
                confirmTitle: "Decline"
            ) { reason in
                Task { await decline(reason: reason) }
            }
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }), presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
        .alert("Done", isPresented: Binding(get: { noticeMessage != nil }, set: { if !$0 { noticeMessage = nil } }), presenting: noticeMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Refund Actions

    @ViewBuilder
    private func refundActions(escrow: Escrow) -> some View {
        let canRefund = (escrow.holdsFunds && !escrow.hasChargeback) && escrow.unreleasedCents > 0

        if escrow.status == "CANCEL_REQUESTED" {
            VStack(spacing: 10) {
                Button {
                    showRefundConfirm = true
                } label: {
                    Text("REFUND \(formatCents(escrow.unreleasedCents))")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(12)
                }

                Button {
                    showDeclineSheet = true
                } label: {
                    Text("DECLINE")
                        .font(.custom("Spectral-Bold", size: 13))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            .disabled(isLoading)
            .padding(.horizontal)
        } else if canRefund {
            // Vendors can always give the money back, e.g. if they can't make the date
            Button {
                showRefundConfirm = true
            } label: {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Refund Customer")
                    }
                }
                .font(.custom("Spectral-Bold", size: 13))
                .foregroundColor(Color(hex: "E60023"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "E60023").opacity(0.08))
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal)
        }
    }

    private func refund() async {
        guard let escrow else { return }
        isLoading = true
        do {
            let response = try await api.refundEscrow(escrowId: escrow.id)
            noticeMessage = response.message ?? "Refund sent"
            await refreshEscrow()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func decline(reason: String) async {
        guard let escrow else { return }
        isLoading = true
        do {
            let response = try await api.declineCancellation(escrowId: escrow.id, reason: reason)
            noticeMessage = response.message
            await refreshEscrow()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func refreshEscrow() async {
        guard let escrowId = escrow?.id else { return }
        do {
            escrow = try await api.getEscrow(escrowId)
        } catch {
            print("❌ Error refreshing escrow: \(error)")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "8B5CF6").opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "8B5CF6"))
            }

            VStack(spacing: 6) {
                Text(project.title)
                    .font(.custom("DelaGothicOne-Regular", size: 22))
                    .multilineTextAlignment(.center)

                if let eventDate = project.eventDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(eventDate, style: .date)
                            .font(.custom("Spectral-Regular", size: 14))
                    }
                    .foregroundColor(.gray)
                }

                if let location = project.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))
                        Text(location)
                            .font(.custom("Spectral-Regular", size: 14))
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Agreement Details

    private var agreementDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR AGREEMENT")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)

            VStack(spacing: 12) {
                if let role = myRole {
                    HStack {
                        Text("Role")
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(role.role)
                            .font(.custom("Spectral-Bold", size: 14))
                    }

                    Divider()

                    HStack {
                        Text("Agreement Amount")
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(role.amountFormatted)
                            .font(.custom("DelaGothicOne-Regular", size: 18))
                    }

                    Divider()

                    HStack {
                        Text("Status")
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                        StatusBadge(status: role.status)
                    }
                }
            }
            .padding()
            .cardStyle()
        }
        .padding(.horizontal)
    }

    // MARK: - Payment Status

    private func paymentStatusCard(escrow: Escrow) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PAYMENT STATUS")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)

            VStack(spacing: 16) {
                let releasedAmount = escrow.releasedCents
                let totalAmount = escrow.amountCents
                let refundedAmount = escrow.refundedAmountCents ?? 0
                let pendingAmount = refundedAmount > 0 ? refundedAmount : totalAmount - releasedAmount

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(Color(hex: "22C55E"))
                            .frame(width: geometry.size.width * CGFloat(releasedAmount) / CGFloat(max(totalAmount, 1)), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RECEIVED")
                            .font(.custom("Spectral-Bold", size: 10))
                            .foregroundColor(Color(hex: "22C55E"))
                        Text(formatCurrency(releasedAmount))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(remainingLabel(escrow))
                            .font(.custom("Spectral-Bold", size: 10))
                            .foregroundColor(escrow.status == "PENDING" || escrow.status == "CANCELED" ? .gray : Color(hex: "3B82F6"))
                        Text(formatCurrency(pendingAmount))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                    }
                }
            }
            .padding()
            .cardStyle()
        }
        .padding(.horizontal)
    }

    // MARK: - Milestones

    private func milestonesSection(escrow: Escrow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MILESTONES")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(escrow.milestones) { milestone in
                    milestoneRow(milestone, escrowStatus: escrow.status)
                }
            }
            .padding(.horizontal)
        }
    }

    private func milestoneRow(_ milestone: Milestone, escrowStatus: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(milestone.released ? Color(hex: "22C55E") : Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: milestone.released ? "checkmark" : "clock")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(milestone.released ? .white : .gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.description ?? "Payment")
                    .font(.custom("Spectral-Medium", size: 14))

                if let dueDate = milestone.dueDate {
                    Text("Due \(dueDate, style: .date)")
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(milestone.amountCents))
                    .font(.custom("DelaGothicOne-Regular", size: 14))

                Text(milestoneStatus(milestone, escrowStatus: escrowStatus))
                    .font(.custom("Spectral-Bold", size: 10))
                    .foregroundColor(milestoneStatusColor(milestone, escrowStatus: escrowStatus))
            }
        }
        .padding()
        .cardStyle()
    }

    private func remainingLabel(_ escrow: Escrow) -> String {
        if (escrow.refundedAmountCents ?? 0) > 0 { return "REFUNDED" }
        switch escrow.status {
        case "PENDING": return "NOT YET FUNDED"
        case "CANCELED": return "CANCELED"
        default: return "IN ESCROW"
        }
    }

    private func milestoneStatus(_ milestone: Milestone, escrowStatus: String) -> String {
        if milestone.released {
            return "PAID"
        } else if milestone.refunded == true {
            return "REFUNDED"
        } else if escrowStatus == "CANCEL_REQUESTED" || escrowStatus == "DISPUTED" {
            return "PAUSED"
        } else if escrowStatus == "CANCELED" {
            return "CANCELED"
        } else if escrowStatus == "PENDING" {
            return "AWAITING FUNDING"
        } else {
            return "IN ESCROW"
        }
    }

    private func milestoneStatusColor(_ milestone: Milestone, escrowStatus: String) -> Color {
        if milestone.released {
            return Color(hex: "22C55E")
        } else if milestone.refunded == true {
            return Color(hex: "3B82F6")
        } else if escrowStatus == "CANCEL_REQUESTED" || escrowStatus == "DISPUTED" {
            return Color(hex: "F59E0B")
        } else if escrowStatus == "PENDING" || escrowStatus == "CANCELED" {
            return .gray
        } else {
            return Color(hex: "3B82F6")
        }
    }

    // MARK: - Customer Contact

    private var customerContactCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CUSTOMER")
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(.gray)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFD700").opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(project.customer.name.prefix(1).uppercased())
                        .font(.custom("DelaGothicOne-Regular", size: 18))
                        .foregroundColor(Color(hex: "FFD700"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.customer.name)
                        .font(.custom("Spectral-Bold", size: 16))

                    Text(project.customer.email)
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Button {
                    if let url = URL(string: "mailto:\(project.customer.email)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .padding(12)
                        .background(Color(hex: "8B5CF6").opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding()
            .cardStyle()
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0"
    }
}

// MARK: - Status Badge (reused)

private struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(statusText)
            .font(.custom("Spectral-Bold", size: 10))
            .foregroundColor(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(4)
    }

    private var statusText: String {
        switch status {
        case "INVITED", "PENDING": return "PENDING"
        case "ACCEPTED": return "ACCEPTED"
        case "DECLINED": return "DECLINED"
        case "PAID": return "IN PROGRESS"
        default: return status
        }
    }

    private var statusColor: Color {
        switch status {
        case "INVITED", "PENDING": return Color(hex: "8B5CF6")
        case "ACCEPTED", "PAID": return Color(hex: "22C55E")
        case "COMPLETED": return Color(hex: "10B981")
        case "DECLINED": return .red
        default: return .gray
        }
    }
}

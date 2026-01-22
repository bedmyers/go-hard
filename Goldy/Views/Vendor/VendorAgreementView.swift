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

    private var myRole: MyVendorRole? {
        project.myVendorRole
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                agreementDetailsCard

                if let escrow = myRole?.escrow {
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
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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
                let releasedAmount = escrow.milestones.filter { $0.released }.reduce(0) { $0 + $1.amountCents }
                let totalAmount = escrow.amountCents
                let pendingAmount = totalAmount - releasedAmount

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
                        Text(escrow.status == "PENDING" ? "NOT YET FUNDED" : "IN ESCROW")
                            .font(.custom("Spectral-Bold", size: 10))
                            .foregroundColor(escrow.status == "PENDING" ? .gray : Color(hex: "3B82F6"))
                        Text(formatCurrency(pendingAmount))
                            .font(.custom("DelaGothicOne-Regular", size: 16))
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func milestoneStatus(_ milestone: Milestone, escrowStatus: String) -> String {
        if milestone.released {
            return "PAID"
        } else if escrowStatus == "PENDING" {
            return "AWAITING FUNDING"
        } else {
            return "IN ESCROW"
        }
    }

    private func milestoneStatusColor(_ milestone: Milestone, escrowStatus: String) -> Color {
        if milestone.released {
            return Color(hex: "22C55E")
        } else if escrowStatus == "PENDING" {
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
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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
        default: return status
        }
    }

    private var statusColor: Color {
        switch status {
        case "INVITED", "PENDING": return Color(hex: "8B5CF6")
        case "ACCEPTED": return Color(hex: "22C55E")
        case "DECLINED": return .red
        default: return .gray
        }
    }
}

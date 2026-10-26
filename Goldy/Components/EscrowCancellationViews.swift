//
//  EscrowCancellationViews.swift
//  Goldy
//
//  Shared UI for escrow cancellation, refunds and disputes (customer and vendor sides)
//

import SwiftUI

// MARK: - Status Banner

/// Explains where an escrow stands when it's not in the normal funded/released flow.
/// Renders nothing for ordinary states.
struct EscrowStatusBanner: View {
    enum Perspective { case customer, vendor }

    let escrow: Escrow
    let perspective: Perspective
    /// The vendor's name when viewed by the customer, the customer's name when viewed by the vendor
    let otherPartyName: String

    var body: some View {
        if let content {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: content.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(content.color)
                    .frame(width: 40, height: 40)
                    .background(content.color.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 6) {
                    Text(content.title)
                        .font(.custom("DelaGothicOne-Regular", size: 16))

                    Text(content.message)
                        .font(.custom("Spectral-Regular", size: 14))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail = content.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.custom("Spectral-Regular", size: 13))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "F5F1E8"))
                            .cornerRadius(8)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.white)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(content.color)
                    .frame(width: 4)
            }
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }

    private struct Content {
        let icon: String
        let color: Color
        let title: String
        let message: String
        var detail: String? = nil
    }

    private var content: Content? {
        let refunded = formatCents(escrow.refundedAmountCents ?? 0)

        switch escrow.status {
        case "CANCEL_REQUESTED":
            let deadline = escrow.cancelResponseDeadline.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "soon"
            switch perspective {
            case .customer:
                let message = escrow.canEscalate
                    ? "\(otherPartyName) didn't respond in time. You can ask Go Hard to decide. Payouts stay paused."
                    : "Waiting for \(otherPartyName) to respond by \(deadline). Payouts are paused until then."
                return Content(icon: "hourglass", color: Color(hex: "FF6B35"), title: "Cancellation Requested", message: message, detail: escrow.cancelReason)
            case .vendor:
                return Content(
                    icon: "exclamationmark.bubble.fill",
                    color: Color(hex: "FF6B35"),
                    title: "Cancellation Requested",
                    message: "\(otherPartyName) asked to cancel. Respond by \(deadline) — refund the \(formatCents(escrow.unreleasedCents)) still in escrow, or decline and Go Hard will decide.",
                    detail: escrow.cancelReason.map { "“\($0)”" }
                )
            }

        case "DISPUTED":
            if escrow.hasChargeback {
                let message = perspective == .customer
                    ? "Your bank is reviewing this payment. Payouts are paused until it's resolved."
                    : "The customer disputed this payment with their bank. Payouts are paused until Stripe resolves it."
                return Content(icon: "building.columns.fill", color: Color(hex: "E60023"), title: "Card Chargeback", message: message)
            }
            return Content(
                icon: "scale.3d",
                color: Color(hex: "8B5CF6"),
                title: "Under Review",
                message: "Go Hard is reviewing this cancellation and will decide what happens to the \(formatCents(escrow.unreleasedCents)) still in escrow. Payouts are paused.",
                detail: escrow.disputeReason
            )

        case "REFUNDED":
            let who = perspective == .customer ? "you" : otherPartyName
            return Content(icon: "arrow.uturn.backward.circle.fill", color: Color(hex: "3B82F6"), title: "Refunded", message: "\(refunded) was returned to \(who). Released payments are final.")

        case "CANCELED":
            return Content(icon: "xmark.circle.fill", color: .gray, title: "Canceled", message: "This escrow was canceled before it was funded. Nothing was charged.", detail: escrow.cancelReason)

        case "COMPLETE" where (escrow.refundedAmountCents ?? 0) > 0:
            return Content(icon: "checkmark.seal.fill", color: Color(hex: "22C55E"), title: "Settled", message: "Go Hard settled this escrow: \(refunded) was refunded and the rest was paid to the vendor.")

        default:
            return nil
        }
    }
}

// MARK: - Reason Sheet

/// Collects a short reason before a cancellation request or a decline.
struct CancellationReasonSheet: View {
    let title: String
    let message: String
    let placeholder: String
    let confirmTitle: String
    let onSubmit: (String) -> Void

    @State private var reason = ""
    @Environment(\.dismiss) private var dismiss

    private var trimmed: String { reason.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.custom("DelaGothicOne-Regular", size: 24))

                Text(message)
                    .font(.custom("Spectral-Regular", size: 15))
                    .foregroundColor(.gray)

                TextField(placeholder, text: $reason, axis: .vertical)
                    .font(.custom("Spectral-Regular", size: 15))
                    .lineLimit(4...8)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                Button {
                    onSubmit(trimmed)
                    dismiss()
                } label: {
                    Text(confirmTitle.uppercased())
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(trimmed.isEmpty ? Color.gray : Color.black)
                        .cornerRadius(12)
                }
                .disabled(trimmed.isEmpty)

                Spacer()
            }
            .padding()
            .background(Color("Background"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Helpers

func formatCents(_ cents: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = cents % 100 == 0 ? 0 : 2
    return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0"
}

#Preview {
    let milestone = Milestone(id: 1, escrowId: 1, description: "Deposit", amountCents: 100000, releaseConditions: nil, dueDate: nil, released: false, createdAt: Date(), updatedAt: Date())
    var escrow = Escrow(id: 1, projectVendorId: 1, buyerId: 1, sellerId: 2, amountCents: 300000, status: "CANCEL_REQUESTED", stripePaymentIntentId: "pi_1", milestones: [milestone], createdAt: Date(), updatedAt: Date())
    escrow.cancelRequestedAt = Date()
    escrow.cancelReason = "Our venue fell through"
    return VStack(spacing: 16) {
        EscrowStatusBanner(escrow: escrow, perspective: .customer, otherPartyName: "Bella Vista Events")
        EscrowStatusBanner(escrow: escrow, perspective: .vendor, otherPartyName: "Jordan")
    }
    .padding()
    .background(Color("Background"))
}

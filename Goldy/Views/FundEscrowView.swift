//
//  FundEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 8/10/25.
//

import SwiftUI
import StripeCore
import StripePayments
import StripePaymentsUI

struct FundEscrowView: View {
    let escrowId: Int
    let amountCents: Int
    let vendorName: String
    var onSuccess: (() -> Void)?

    @AppStorage("authToken") private var authToken = ""

    @State private var cardFormRef: STPCardFormView?
    @State private var isLoading = false
    @State private var errorText = ""
    @Environment(\.dismiss) var dismiss

    init(escrowId: Int, amountCents: Int = 0, vendorName: String = "", onSuccess: (() -> Void)? = nil) {
        self.escrowId = escrowId
        self.amountCents = amountCents
        self.vendorName = vendorName
        self.onSuccess = onSuccess
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: Double(amountCents) / 100.0)) ?? "$0"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "22C55E"))

                        Text("Fund Escrow")
                            .font(.custom("DelaGothicOne-Regular", size: 24))

                        Text("Securely hold funds until milestones are completed")
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Amount summary
                    if amountCents > 0 {
                        VStack(spacing: 16) {
                            if !vendorName.isEmpty {
                                HStack {
                                    Text("Vendor")
                                        .font(.custom("Spectral-Regular", size: 14))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(vendorName)
                                        .font(.custom("Spectral-Medium", size: 14))
                                }
                            }

                            Divider()

                            HStack {
                                Text("Total Amount")
                                    .font(.custom("Spectral-Regular", size: 14))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(formattedAmount)
                                    .font(.custom("DelaGothicOne-Regular", size: 20))
                            }
                        }
                        .padding()
                        .background(Color(hex: "F9FAFB"))
                        .cornerRadius(12)
                    }

                    // Card input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CARD DETAILS")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        CardFormRepresentable(formRef: $cardFormRef)
                            .frame(height: 200)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    if !errorText.isEmpty {
                        Text(errorText)
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Spacer(minLength: 20)

                    // Submit button
                    VStack(spacing: 12) {
                        Button {
                            Task { await fund() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "lock.fill")
                                    Text(amountCents > 0 ? "FUND \(formattedAmount)" : "FUND ESCROW")
                                        .font(.custom("DelaGothicOne-Regular", size: 14))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)

                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Funds held securely until you release them")
                                .font(.custom("Spectral-Regular", size: 11))
                        }
                        .foregroundColor(.gray)
                    }
                }
                .padding()
            }
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

    func fund() async {
        isLoading = true; defer { isLoading = false }
        errorText = ""

        guard let pmParams: STPPaymentMethodParams = cardFormRef?.cardParams else {
            errorText = "Enter a valid card."
            return
        }

        let billing = STPPaymentMethodBillingDetails()
        pmParams.billingDetails = billing

        do {
            print("💳 Creating payment method...")
            let pm = try await createPaymentMethod(with: pmParams)
            print("✅ Payment method created: \(pm.stripeId)")

            let url = URL(string: "https://go-hard-backend-production.up.railway.app/escrow/\(escrowId)/fund")!
            print("🌐 Funding escrow at: \(url)")

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            req.httpBody = try JSONSerialization.data(withJSONObject: [
                "paymentMethodId": pm.stripeId
            ])

            let (data, resp) = try await URLSession.shared.data(for: req)
            let http = resp as? HTTPURLResponse
            let statusCode = http?.statusCode ?? -1
            let responseBody = String(data: data, encoding: .utf8) ?? "nil"

            print("📦 Response [\(statusCode)]: \(responseBody)")

            guard (200...299).contains(statusCode) else {
                // Try to parse error message from response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? String {
                    errorText = errorMsg
                } else {
                    errorText = "Server error (\(statusCode)): \(responseBody)"
                }
                return
            }
            onSuccess?()
            dismiss()
        } catch {
            print("❌ Fund error: \(error)")
            errorText = error.localizedDescription
        }
    }

    private func createPaymentMethod(with params: STPPaymentMethodParams) async throws -> STPPaymentMethod {
        try await withCheckedThrowingContinuation { cont in
            STPAPIClient.shared.createPaymentMethod(with: params) { pm, err in
                if let err = err { cont.resume(throwing: err) }
                else if let pm = pm { cont.resume(returning: pm) }
                else { cont.resume(throwing: NSError(domain: "Stripe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])) }
            }
        }
    }
}

struct CardFormRepresentable: UIViewRepresentable {
    @Binding var formRef: STPCardFormView?

    func makeUIView(context: Context) -> STPCardFormView {
        let view = STPCardFormView()
        // hand the reference back to SwiftUI state
        DispatchQueue.main.async { self.formRef = view }
        return view
    }
    func updateUIView(_ uiView: STPCardFormView, context: Context) {}
}

#Preview {
    FundEscrowPreviewHost()
}

private struct FundEscrowPreviewHost: View {
    init() {
        UserDefaults.standard.set("preview-token", forKey: "authToken")
        // StripeAPI.defaultPublishableKey = "pk_test_..." // optional for live preview
    }
    var body: some View {
        NavigationStack {
            FundEscrowView(escrowId: 123).navigationTitle("Fund Escrow")
        }
    }
}


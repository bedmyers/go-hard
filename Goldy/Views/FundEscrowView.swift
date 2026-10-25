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

            var result = try await postToEscrow("fund", body: ["paymentMethodId": pm.stripeId])

            // The card's bank wants the customer to verify (3D Secure). Show Stripe's
            // verification screen, then have the backend re-check the payment.
            if result.status == "requires_action", let clientSecret = result.clientSecret {
                let (actionStatus, actionError) = await handleNextAction(clientSecret: clientSecret)
                switch actionStatus {
                case .succeeded:
                    result = try await postToEscrow("confirm", body: [:])
                case .canceled:
                    errorText = "Card verification was canceled. You have not been charged."
                    return
                case .failed:
                    errorText = actionError?.localizedDescription ?? "Card verification failed. Try another card."
                    return
                @unknown default:
                    errorText = "Card verification failed. Try another card."
                    return
                }
            }

            // Only treat the escrow as funded when the backend says so
            guard result.status == "funded" else {
                errorText = "Payment didn't go through. Try another card."
                return
            }
            onSuccess?()
            dismiss()
        } catch FundError.server(let message) {
            errorText = message
        } catch {
            print("❌ Fund error: \(error)")
            errorText = error.localizedDescription
        }
    }

    private struct FundResponse: Decodable {
        let status: String?
        let clientSecret: String?
        let error: String?
    }

    private enum FundError: Error {
        case server(String)
    }

    /// POSTs to /escrow/:id/<action> and decodes the response, throwing the server's error message on failure.
    private func postToEscrow(_ action: String, body: [String: Any]) async throws -> FundResponse {
        let url = URL(string: "https://go-hard-backend-production.up.railway.app/escrow/\(escrowId)/\(action)")!

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let statusCode = (resp as? HTTPURLResponse)?.statusCode ?? -1
        print("📦 /escrow/\(escrowId)/\(action) response [\(statusCode)]")

        let decoded = try? JSONDecoder().decode(FundResponse.self, from: data)
        guard (200...299).contains(statusCode), let decoded else {
            throw FundError.server(decoded?.error ?? "Something went wrong (\(statusCode)). Please try again.")
        }
        return decoded
    }

    /// Presents Stripe's 3D Secure verification for a PaymentIntent confirmed on the server.
    private func handleNextAction(clientSecret: String) async -> (STPPaymentHandlerActionStatus, NSError?) {
        let context = AuthenticationContext()
        return await withCheckedContinuation { cont in
            STPPaymentHandler.shared().handleNextAction(forPayment: clientSecret, with: context, returnURL: nil) { status, _, error in
                cont.resume(returning: (status, error))
            }
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

/// Gives Stripe a view controller to present 3D Secure screens on (the top-most one, i.e. this sheet).
private final class AuthenticationContext: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        MainActor.assumeIsolated {
            let keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
            var top = keyWindow?.rootViewController ?? UIViewController()
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
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


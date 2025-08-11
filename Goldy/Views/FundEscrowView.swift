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
    @AppStorage("authToken") private var authToken = ""

    @State private var cardFormRef: STPCardFormView?   // <- keep a reference
    @State private var isLoading = false
    @State private var errorText = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            CardFormRepresentable(formRef: $cardFormRef)
                .frame(height: 200)

            Button(isLoading ? "Processing..." : "Fund Escrow") {
                Task { await fund() }
            }
            .disabled(isLoading)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)

            if !errorText.isEmpty { Text(errorText).foregroundColor(.red) }
            Spacer()
        }
        .padding()
    }

    func fund() async {
        isLoading = true; defer { isLoading = false }
        errorText = ""

        // STPCardFormView.cardParams -> STPPaymentMethodParams
        guard let pmParams: STPPaymentMethodParams = cardFormRef?.cardParams else {
            errorText = "Enter a valid card."
            return
        }

        // Optional: add billing details
        let billing = STPPaymentMethodBillingDetails()
        // e.g. billing.name = "Blair Myers"
        pmParams.billingDetails = billing

        do {
            let pm = try await createPaymentMethod(with: pmParams)

            var req = URLRequest(url: URL(string: "https://go-hard-backend-production.up.railway.app/escrow/fund")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            req.httpBody = try JSONSerialization.data(withJSONObject: [
                "escrowId": escrowId,
                "paymentMethodId": pm.stripeId
            ])

            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }

    // Wrap Stripe's completion-based API in async/await
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

// SwiftUI wrapper that gives you a reference to the UIKit card form
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


/*
 import StripeCore
 @main struct YourApp: App {
     init() { StripeAPI.defaultPublishableKey = "pk_test_..." }
     var body: some Scene { WindowGroup { RootView() } }
 }
 */

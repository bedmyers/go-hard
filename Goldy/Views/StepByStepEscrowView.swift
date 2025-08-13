//
//  StepByStepEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 7/19/25.
//

import SwiftUI

struct StepByStepEscrowView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: EscrowViewModel

    @AppStorage("userId") var userId: Int = 0
    @AppStorage("authToken") var authToken: String = ""

    @State private var step = 0

    // Collected data
    @State private var escrowName = ""
    @State private var purposeText = ""
    @State private var totalAmountText = ""
    @State private var releaseNotes = ["", "", ""]
    @State private var selectedSellerId: Int = 0 // update later with search

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("CREATE AN ESCROW")
                .font(.custom("DelaGothicOne-Regular", size: 30))
                .padding(.bottom, 50)

            currentStepView()
                .padding(.bottom, 20)

            // Uses your existing ProgressBar component
            ProgressBar(progress: Double(step) / 4)
                .frame(height: 30)

            Spacer()

            Button(action: nextStep) {
                Text(step == 4 ? "FINISH" : "NEXT")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background").ignoresSafeArea())
    }

    @ViewBuilder
    func currentStepView() -> some View {
        switch step {
        case 0:
            VStack(alignment: .leading) {
                Text("What is the escrow name?")
                    .font(.custom("DaysOne-Regular", size: 36))
                TextField("Start typing...", text: $escrowName)
                    .font(.custom("IBMPlexMono-Regular", size: 14))
                    .textFieldStyle(.roundedBorder)
            }
        case 1:
            VStack(alignment: .leading) {
                Text("What is the purpose of this escrow?")
                TextField("Describe the purpose", text: $purposeText)
                    .font(.custom("IBMPlexMono-Regular", size: 14))
                    .textFieldStyle(.roundedBorder)
            }
        case 2:
            VStack(alignment: .leading) {
                Text("What is the total escrowed amount?")
                TextField("e.g. 1500", text: $totalAmountText)
                    .font(.custom("IBMPlexMono-Regular", size: 14))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
        case 3:
            VStack(alignment: .leading, spacing: 12) {
                Text("What are the conditions for release?")
                ForEach(releaseNotes.indices, id: \.self) { i in
                    TextField("Milestone \(i + 1)", text: $releaseNotes[i])
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .textFieldStyle(.roundedBorder)
                }
            }
        case 4:
            VStack(alignment: .leading) {
                Text("Confirm and Submit?")
                Text("Escrow Name: \(escrowName)")
                Text("Purpose: \(purposeText)")
                Text("Amount: \(totalAmountText)")
                ForEach(releaseNotes.indices, id: \.self) { i in
                    Text("Milestone \(i + 1): \(releaseNotes[i])")
                }
            }
        default:
            EmptyView()
        }
    }

    func nextStep() {
        if step < 4 {
            step += 1
        } else {
            submitEscrow()
        }
    }

    func submitEscrow() {
        guard let totalAmount = Double(totalAmountText), totalAmount > 0 else {
            print("❌ Invalid amount")
            return
        }
        guard selectedSellerId != 0 else {
            print("❌ Select a seller")
            return
        }

        // Simple even split for any non-empty milestones provided
        let nonEmptyNotes = releaseNotes.filter { !$0.isEmpty }
        let splitCount = max(1, nonEmptyNotes.count)
        let perMilestone = totalAmount / Double(splitCount)

        let milestones: [[String: Any]] = (0..<splitCount).map { _ in
            ["amount": perMilestone, "released": false]
        }

        let payload: [String: Any] = [
            "title": escrowName,
            "buyerId": userId,
            "sellerId": selectedSellerId,
            "amount": totalAmount,
            "milestones": milestones
        ]

        guard let url = URL(string: "https://go-hard-backend-production.up.railway.app/escrow/create"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ Failed to encode payload")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                print("❌ No data returned")
                return
            }

            do {
                // Decode the server response as EscrowDTO, then map to your UI model
                let dto = try JSONDecoder().decode(EscrowDTO.self, from: data)
                let project = dto.toProject()

                DispatchQueue.main.async {
                    viewModel.addEscrow(project)
                    dismiss()
                }
            } catch {
                print("❌ Decoding error:", error)
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }.resume()
    }
}

#Preview {
    StepByStepEscrowView(viewModel: EscrowViewModel())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background").ignoresSafeArea())
}

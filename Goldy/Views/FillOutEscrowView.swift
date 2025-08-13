//
//  FillOutEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 6/6/25.
//

import SwiftUI

struct FillOutEscrowView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: EscrowViewModel

    @State private var purposeText: String = ""
    @State private var escrowFund = EscrowFund(text: "", amount: nil)
    @State private var releaseFunds: [EscrowFund] = Array(repeating: EscrowFund(text: "", amount: nil), count: 3)
    @State private var cancellationPolicyText: String = ""
    @State private var selectedSellerId: Int = 0
    @State private var amountText: String = ""
    @State private var editableEscrowName: String = ""

    @StateObject private var userSearchVM = UserSearchViewModel()
    @State private var searchText: String = ""
    @State private var selectedUsers: [User] = []
    @State private var showUserSearch = false

    var escrowName: String
    var parties: [String]

    @AppStorage("userId") var userId: Int = 0
    @AppStorage("authToken") var authToken: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Title
                HStack {
                    Text("CREATE AN ESCROW")
                        .font(.custom("DelaGothicOne-Regular", size: 30))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.title2)
                }

                // Escrow Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("ESCROW NAME")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    TextField("Start typing...", text: $editableEscrowName)
                        .frame(maxHeight: 35)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .multilineTextAlignment(.leading)
                }

                // MARK: - Party Avatars Row
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD A PARTY")
                        .font(.custom("DelaGothicOne-Regular", size: 14))

                    HStack(spacing: 16) {
                        ForEach(selectedUsers, id: \.id) { user in
                            if let imageName = user.avatarImageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Text(initials(for: user.name))
                                    .font(.custom("DelaGothicOne-Regular", size: 18))
                                    .frame(width: 50, height: 50)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }

                        Button(action: { showUserSearch = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                }

                // Terms & Conditions
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD TERMS & CONDITIONS")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    HStack(spacing: 8) {
                        Button(action: {}) {
                            Text("UPLOAD")
                                .font(.custom("DelaGothicOne-Regular", size: 14))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, maxHeight: 35)
                                .padding()
                                .background(Color("Button"))
                                .cornerRadius(50)
                        }
                        Button(action: {}) {
                            Text("CREATE")
                                .font(.custom("DelaGothicOne-Regular", size: 14))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, maxHeight: 35)
                                .padding()
                                .background(Color("Button"))
                                .cornerRadius(50)
                        }
                    }
                    .padding(.bottom, 20)
                }

                // Purpose
                VStack(alignment: .leading, spacing: 6) {
                    Text("PURPOSE OF THE ESCROW")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    TextField("Start typing...", text: $purposeText)
                        .frame(height: 85)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .multilineTextAlignment(.leading)
                }

                // Escrowed Funds
                VStack(alignment: .leading, spacing: 6) {
                    Text("ESCROWED FUNDS")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    EscrowFundCard(fund: $escrowFund)
                }

                // Conditions for Release
                VStack(alignment: .leading, spacing: 6) {
                    Text("CONDITIONS FOR RELEASE")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    ForEach(releaseFunds.indices, id: \.self) { i in
                        EscrowFundCard(fund: $releaseFunds[i])
                    }
                }

                // Cancellation Policy
                VStack(alignment: .leading, spacing: 6) {
                    Text("CANCELLATION & REFUND POLICY")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    TextField("Start typing...", text: $cancellationPolicyText)
                        .frame(height: 85)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .multilineTextAlignment(.leading)
                }

                // Signed and Agreed
                VStack(alignment: .leading, spacing: 8) {
                    Text("SIGNED AND AGREED")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    HStack(spacing: 16) {
                        ForEach(["profile1", "profile2"], id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                    }
                    Text("Unexecuted")
                        .font(.custom("DaysOne-Regular", size: 12))
                        .opacity(0.35)
                }

                // Save & Share
                Button(action: submitEscrow) {
                    Text("SAVE & SHARE")
                        .font(.custom("DaysOne-Regular", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(24)
                }

                // Save For Later
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Text("SAVE FOR LATER")
                            .font(.custom("DelaGothicOne-Regular", size: 12))
                            .foregroundStyle(.black)
                            .underline()
                            .padding(.top, 4)
                    }
                    Spacer()
                }
            }
            .padding()
        }
        .onAppear {
            editableEscrowName = escrowName
        }
        .sheet(isPresented: $showUserSearch) {
            UserSearchSheetView(
                viewModel: userSearchVM,
                currentUserId: userId
            ) { user in
                selectedUsers = [user]
                selectedSellerId = user.id
            }
        }
        .background(Color("Background").ignoresSafeArea())
    }

    func submitEscrow() {
        guard let totalAmount = escrowFund.amount, totalAmount > 0 else {
            print("❌ Missing escrowed amount")
            return
        }
        guard selectedSellerId != 0 else {
            print("❌ Select a seller")
            return
        }

        // Build milestone payload from entered amounts
        let milestonePayload = releaseFunds
            .compactMap { $0.amount }
            .map { ["amount": $0, "released": false] }

        let payload: [String: Any] = [
            "title": editableEscrowName,
            "buyerId": userId,
            "sellerId": selectedSellerId,
            "amount": totalAmount,
            "milestones": milestonePayload
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
                // Decode EscrowDTO returned by backend, then map to your UI model
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

    func initials(for name: String) -> String {
        let comps = name.split(separator: " ")
        let first = comps.first?.prefix(1) ?? ""
        let last = comps.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }
}

struct EscrowFund {
    var text: String
    var amount: Double?
}

// MARK: - EscrowFundCard View

private struct EscrowFundCard: View {
    @Binding var fund: EscrowFund
    @State private var amountText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Start typing...", text: $fund.text)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text("$")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.gray)

                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.yellow)
                .cornerRadius(50)
                .frame(width: 110)
                .onChange(of: amountText) { newValue in
                    fund.amount = Double(newValue)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            if let amount = fund.amount {
                amountText = String(format: "%.2f", amount)
            }
        }
    }
}

#Preview {
    let vm = EscrowViewModel()
    FillOutEscrowView(
        viewModel: vm, escrowName: "Cabochon Jewelry",
        parties: ["profile1", "profile2"]
    )
}

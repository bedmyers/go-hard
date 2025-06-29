//
//  FillOutEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 6/6/25.
//

import SwiftUI

struct FillOutEscrowView: View {
    @State private var escrowName: String = ""
    @State private var purposeText: String = ""
    @State private var escrowFund = EscrowFund(text: "", amount: nil)
    @State private var releaseFunds: [EscrowFund] = Array(repeating: EscrowFund(text: "", amount: nil), count: 3)
    @State private var cancellationPolicyText: String = ""

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
                    TextField("Start typing...", text: $escrowName)
                        .frame(maxHeight: 35)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .multilineTextAlignment(.leading)
                }

                // Party Avatars
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADD A PARTY")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                    HStack(spacing: 16) {
                        ForEach(["profile1", "profile2"], id: \.self) { name in
                            Image(name)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        Button(action: {}) {
                            Image(systemName: "plus")
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

                // Escrowed Funds (single box)
                VStack(alignment: .leading, spacing: 6) {
                    Text("ESCROWED FUNDS")
                        .font(.custom("DelaGothicOne-Regular", size: 14))

                    EscrowFundCard(fund: $escrowFund)
                }

                // Conditions for Release (3 boxes)
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
                Button(action: {}) {
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
        .background(Color("Background").ignoresSafeArea())
    }
}

struct EscrowFund {
    var text: String
    var amount: Double?
}

// MARK: - EscrowFundCard View

private struct EscrowFundCard: View {
    @Binding var fund: EscrowFund

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Start typing...", text: $fund.text)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                Text(fund.amount != nil
                     ? "$\(fund.amount!, specifier: "%.2f") USD"
                     : "– USD")
                    .font(.custom("DelaGothicOne-Regular", size: 13))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(50)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    FillOutEscrowView()
}

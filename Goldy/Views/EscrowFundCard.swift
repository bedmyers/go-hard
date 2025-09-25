//
//  EscrowFundCard.swift
//  Goldy
//
//  Created by Blair Myers on 9/17/25.
//

import SwiftUI

struct EscrowFund {
    var text: String
    var amount: Double?
}

struct EscrowFundCard: View {
    @Binding var fund: EscrowFund
    @State private var amountText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Start typing...", text: $fund.text)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
                .textFieldStyle(PlainTextFieldStyle())

            HStack {
                Spacer()
                
                HStack(spacing: 4) {
                    Text("$")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.black)
                        .opacity(0.7)

                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.yellow.opacity(0.8))
                .cornerRadius(50)
                .frame(width: 110)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onChange(of: amountText) { newValue in
            fund.amount = Double(newValue)
        }
        .onAppear {
            if let amount = fund.amount {
                amountText = String(format: "%.2f", amount)
            }
        }
    }
}

#Preview {
    @State var sampleFund = EscrowFund(text: "Sample description", amount: 100.00)
    
    return VStack(spacing: 20) {
        EscrowFundCard(fund: $sampleFund)
        EscrowFundCard(fund: .constant(EscrowFund(text: "", amount: nil)))
    }
    .padding()
    .background(Color(red: 0.97, green: 0.93, blue: 0.85))
}

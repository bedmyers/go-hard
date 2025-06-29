//
//  MakeAPaymentView.swift
//  Goldy
//
//  Created by Blair Myers on 6/15/25.
//

import SwiftUI

struct MakePaymentView: View {
    @State private var amount: String = ""
    @State private var escrowName: String = "Cabochen Jewelry"
    @State private var selectedAction: ActionType = .send

    enum ActionType {
        case send, request
    }

    var body: some View {
        VStack(spacing: 32) {
            
            // MARK: - Header
            HStack {
                Text("MAKE A PAYMENT")
                    .font(.custom("DelaGothicOne-Regular", size: 22))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.title2)
            }
            .padding(.horizontal)
            .padding(.top, 30)
            
            // MARK: - Amount
            TextField("", text: $amount)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.custom("DelaGothicOne-Regular", size: 50))
                .frame(height: 70)
                .overlay(
                    Text("$")
                        .font(.custom("DelaGothicOne-Regular", size: 50))
                        .offset(x: -UIScreen.main.bounds.width / 4),
                    alignment: .leading
                )
                .padding(.horizontal)
            
            // MARK: - Escrow name
            TextField("Escrow Name", text: $escrowName)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .font(.custom("DaysOne-Regular", size: 16))
            
            // MARK: - Action Buttons
            HStack(spacing: 0) {
                Button(action: { selectedAction = .send }) {
                    Text("SEND")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .background(selectedAction == .send ? Color.black : Color("Button"))
                        .foregroundColor(selectedAction == .send ? .white : .black)
                }

                Button(action: { selectedAction = .request }) {
                    Text("REQUEST")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .background(selectedAction == .request ? Color.black : Color("Button"))
                        .foregroundColor(selectedAction == .request ? .white : .black)
                }
            }
            .cornerRadius(16)
            .padding(.horizontal)

            Spacer()
        }
        .background(Color("Background").ignoresSafeArea())
    }
}

#Preview {
    MakePaymentView()
}

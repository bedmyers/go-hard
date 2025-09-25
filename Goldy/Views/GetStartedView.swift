//
//  GetStartedView.swift
//  Goldy
//
//  Created by Blair Myers on 7/8/25.
//

import SwiftUI

struct GetStartedView: View {
    @ObservedObject var viewModel: EscrowViewModel
    @State private var showCreateEscrow = false

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("GET STARTED")
                    .font(.custom("DelaGothicOne-Regular", size: 30))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.title2)
            }
            .padding(.bottom, 150)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                getStartedButton("CREATE AN ESCROW") {
                    showCreateEscrow = true
                }
                getStartedButton("JOIN AN ESCROW") {
                    // Not implemented yet
                }
                getStartedButton("MAKE A PAYMENT") {
                    // Show payment screen
                }
                getStartedButton("BUILD YOUR PROFILE") {
                    // Optional: show profile builder
                }
            }
        }
        .sheet(isPresented: $showCreateEscrow) {
            CreateEscrowView(viewModel: viewModel)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background").ignoresSafeArea())
    }

    func getStartedButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("DaysOne-Regular", size: 20))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading)
            .background(Color("ActiveColor"))
            .cornerRadius(16)
        }
    }
}

#Preview {
    GetStartedView(viewModel: EscrowViewModel())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Background").ignoresSafeArea())
}

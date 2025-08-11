//
//  CreateEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

struct CreateEscrowView: View {
    var viewModel: EscrowViewModel

    @State private var escrowName: String = ""
    @State private var parties: [String] = ["profile1", "profile2"]
    @State private var showFillOut = false
    
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            VStack {
                TitleSection(title: "CREATE AN \n ESCROW")
                    .padding(.bottom, 50)
                
                EscrowNameField(escrowName: $escrowName)
                    .padding(.bottom, 40)
                
                PartyList(parties: $parties) {
                    // TODO: Add party logic
                }
                .padding(.bottom, 40)
                
                TermsConditionsSection(
                    uploadAction: {
                        // TODO: Upload logic
                    },
                    fillOutAction: {
                        showFillOut = true
                    }
                )
                .padding(.bottom, 35)
                
                SaveForLaterView()
                    .padding(.bottom, 10)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showFillOut) {
            FillOutEscrowView(
                viewModel: viewModel, escrowName: escrowName,
                parties: parties
            )
        }
    }
}

// MARK: - TitleSection
struct TitleSection: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.custom("DelaGothicOne-Regular", size: 30))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - EscrowNameField
struct EscrowNameField: View {
    @Binding var escrowName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ESCROW NAME")
                .font(.custom("DelaGothicOne-Regular", size: 16))
            
            TextField("Start typing...", text: $escrowName)
                .frame(height: 30)
                .padding(.leading, 15)
                .font(.custom("IBMPlexMono-Regular", size: 16))
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .shadow(radius: 2)
        }
    }
}

// MARK: - PartyList
// MARK: - PartyList
struct PartyList: View {
    @Binding var parties: [String]
    var addPartyAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: parties.isEmpty ? 0 : 16) {
            // Left-align the "ADD A PARTY" label
            Text("ADD A PARTY")
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // This HStack will list party images, then the plus button
            HStack(spacing: 16) {
                ForEach(parties, id: \.self) { party in
                    Image(party)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
                
                // Plus button to add more parties
                Button(action: {
                    addPartyAction()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                        .frame(width: 70, height: 60)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            // Make sure the HStack is left-aligned
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - TermsConditionsSection
struct TermsConditionsSection: View {
    var uploadAction: () -> Void
    var fillOutAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ADD TERMS & CONDITIONS")
                .font(.custom("DelaGothicOne-Regular", size: 16))
            
            HStack(spacing: 8) {
                Button(action: uploadAction) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UPLOAD T&C FROM FILES")
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
                
                Button(action: fillOutAction) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CREATE ESCROW WITHOUT T&C")
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
    }
}

struct SaveForLaterView: View {
    
    var body: some View {
        Text("SAVE FOR LATER")
            .font(.custom("DelaGothicOne-Regular", size: 12))
            .underline()
    }
}

// MARK: - Preview
#Preview {
    CreateEscrowView(viewModel: EscrowViewModel())
}

//
//  StatBox.swift
//  Goldy
//
//  Small labeled stat (budget, bids, time left) used on RFP cards
//

import SwiftUI

struct StatBox: View {
    let icon: String
    let label: String
    let value: String
    var bgColor: Color
    var valueColor: Color = .black

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.custom("Spectral-Regular", size: 10))
                    .foregroundColor(.gray)
                Text(label)
                    .font(.custom("Spectral-Bold", size: 9))
                    .foregroundColor(.gray)
            }

            Text(value)
                .font(.custom("Spectral-Bold", size: 12))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(bgColor)
        .cornerRadius(8)
    }
}

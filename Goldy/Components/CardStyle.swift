//
//  CardStyle.swift
//  Goldy
//
//  The standard white card from the design system: white background, rounded
//  corners (12–16pt) and one subtle shadow, so every card looks the same.
//

import SwiftUI

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

extension View {
    /// White card with the app's standard corner radius and shadow
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Standard card")
            .font(.custom("Spectral-Medium", size: 15))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardStyle()

        Text("Large card (16pt corners)")
            .font(.custom("Spectral-Medium", size: 15))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .cardStyle(cornerRadius: 16)
    }
    .padding()
    .background(Color("Background"))
}

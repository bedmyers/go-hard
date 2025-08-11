//
//  ProgressBarView.swift
//  Goldy
//
//  Created by Blair Myers on 7/19/25.
//

import SwiftUI

struct ProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height: CGFloat = 30
            let indicatorSize: CGFloat = 30
            let clampedProgress = max(0.0, min(progress, 1.0))
            let xOffset = (width - indicatorSize) * clampedProgress

            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color("ActiveColor"))
                    .frame(height: height)

                // Filled indicator with % text
                Text("\(Int(clampedProgress * 100))%")
                    .font(.custom("DelaGothicOne-Regular", size: 12))
                    .foregroundColor(.black)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color("ActiveColor"), lineWidth: 1)
                    )
                    .offset(x: xOffset)
            }
        }
        .frame(height: 30)
    }
}

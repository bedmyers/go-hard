//
//  AppBackgroundView.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

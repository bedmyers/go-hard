//
//  AppAppearance.swift
//  Goldy
//
//  App-wide UIKit appearance so system-drawn chrome (navigation titles, segmented
//  controls) uses the design system fonts instead of San Francisco.
//

import SwiftUI
import UIKit

enum AppAppearance {
    static let titleFont = "DelaGothicOne-Regular"
    static let bodyBoldFont = "Spectral-Bold"

    /// Call once at launch, before any navigation bar is created.
    static func configure() {
        let navBar = UINavigationBar.appearance()
        if let largeTitle = UIFont(name: titleFont, size: 30) {
            navBar.largeTitleTextAttributes = [.font: largeTitle]
        }
        if let inlineTitle = UIFont(name: titleFont, size: 17) {
            navBar.titleTextAttributes = [.font: inlineTitle]
        }

        if let segmentFont = UIFont(name: bodyBoldFont, size: 14) {
            let segmented = UISegmentedControl.appearance()
            segmented.setTitleTextAttributes([.font: segmentFont], for: .normal)
            segmented.setTitleTextAttributes([.font: segmentFont], for: .selected)
        }
    }
}

#Preview("Navigation & segmented style") {
    @Previewable @State var tab = 0
    let _ = AppAppearance.configure()

    NavigationStack {
        VStack {
            Picker("Tab", selection: $tab) {
                Text("My RFPs").tag(0)
                Text("Find Vendors").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            Spacer()
        }
        .background(Color("Background"))
        .navigationTitle("Discover")
    }
}

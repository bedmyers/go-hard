//
//  ErrorMessageView.swift
//  Goldy
//
//  Inline red error banner used on the login and signup forms
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(message)
                .font(.callout)
            Spacer()
            Text("Tap to dismiss")
                .font(.caption2)
                .foregroundColor(.red.opacity(0.7))
        }
        .foregroundColor(.red)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.top, 8)
    }
}

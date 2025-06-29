//
//  LabelTextField.swift
//  Goldy
//
//  Created by Blair Myers on 3/1/25.
//

import SwiftUI

struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.custom("DelaGothicOne-Regular", size: 16))
                .foregroundColor(.black)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .frame(height: 35)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .font(.body)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .frame(height: 35)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .font(.body)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.none)
            }
        }
    }
}

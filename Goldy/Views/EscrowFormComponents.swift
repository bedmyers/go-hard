//
//  EscrowFormComponents.swift
//  Goldy
//
//  Created by Blair Myers on 9/17/25.
//

import SwiftUI

// MARK: - Reusable Form Components

struct EscrowButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(isDisabled ? .secondary : .black)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDisabled ? Color(.systemGray5) : Color("Button"))
                )
        }
        .disabled(isDisabled)
    }
}

struct EscrowSectionHeader: View {
    let title: String
    var isRequired: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(.primary)
            
            if isRequired {
                Text("*")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.red)
            }
        }
    }
}

struct ValidationErrorText: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.custom("IBMPlexMono-Regular", size: 12))
            .foregroundColor(.red)
            .padding(.top, 4)
    }
}

// MARK: - Text Field Styles

struct EscrowTextFieldStyle: TextFieldStyle {
    var hasError: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.custom("IBMPlexMono-Regular", size: 14))
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasError ? Color.red : Color(.systemGray4), lineWidth: 1)
            )
            .frame(minHeight: 44)
    }
}

struct EscrowTextAreaStyle: TextFieldStyle {
    var hasError: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.custom("IBMPlexMono-Regular", size: 14))
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasError ? Color.red : Color(.systemGray4), lineWidth: 1)
            )
            .frame(minHeight: 100, alignment: .topLeading)
    }
}

#Preview {
    VStack(spacing: 20) {
        EscrowSectionHeader(title: "SAMPLE SECTION", isRequired: true)
        
        EscrowButton(title: "Normal Button") {}
        EscrowButton(title: "Disabled Button", action: {}, isDisabled: true)
        
        TextField("Sample Text Field", text: .constant(""))
            .textFieldStyle(EscrowTextFieldStyle())
        
        TextField("Error State", text: .constant(""))
            .textFieldStyle(EscrowTextFieldStyle(hasError: true))
        
        ValidationErrorText(message: "This field is required")
        
        TextField("Sample Text Area", text: .constant(""), axis: .vertical)
            .textFieldStyle(EscrowTextAreaStyle())
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

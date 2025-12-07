//
//  VendorQuickProfileView.swift
//  Goldy
//
//  Created by Blair Myers on 11/8/25.
//

import SwiftUI

struct VendorQuickProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedServices: Set<String> = []
    @State private var bio = ""
    @State private var yearsExperience = ""
    
    let services = [
        "Photography", "Videography", "Catering",
        "DJ/Music", "Florist", "Venue",
        "Planning", "Makeup", "Hair Styling",
        "Decor", "Bakery", "Bartending"
    ]
    
    var canContinue: Bool {
        !selectedServices.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QUICK PROFILE SETUP")
                                .font(.custom("DelaGothicOne-Regular", size: 28))
                            
                            Text("This helps customers find you")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 8)
                        
                        // Services Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "YOUR SERVICES",
                                subtitle: "Select all that apply",
                                required: true
                            )
                            
                            ServiceCardGrid(
                                services: services,
                                selectedServices: $selectedServices
                            )
                        }
                        
                        // Bio Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "ABOUT YOU",
                                subtitle: "Tell customers about your experience",
                                required: false
                            )
                            
                            TextEditor(text: $bio)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        // Experience Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "YEARS OF EXPERIENCE",
                                subtitle: "How long have you been in business?",
                                required: false
                            )
                            
                            TextField("e.g., 5", text: $yearsExperience)
                                .keyboardType(.numberPad)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveProfile()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(canContinue ? .black : .gray)
                    }
                    .disabled(!canContinue)
                }
            }
        }
    }
    
    private func saveProfile() {
        UserDefaults.standard.set(Array(selectedServices), forKey: "vendorServices")
        UserDefaults.standard.set(bio, forKey: "vendorBio")
        UserDefaults.standard.set(yearsExperience, forKey: "vendorExperience")
        UserDefaults.standard.set(true, forKey: "hasSetupProfile")
    }
}

// MARK: - Section Header
private struct SectionHeader: View {
    let title: String
    let subtitle: String
    let required: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                
                if required {
                    Text("*")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(.red)
                }
            }
            
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Service Card Grid
private struct ServiceCardGrid: View {
    let services: [String]
    @Binding var selectedServices: Set<String>
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(services, id: \.self) { service in
                ServiceCard(
                    title: service,
                    isSelected: selectedServices.contains(service)
                ) {
                    if selectedServices.contains(service) {
                        selectedServices.remove(service)
                    } else {
                        selectedServices.insert(service)
                    }
                }
            }
        }
    }
}

// MARK: - Service Card
private struct ServiceCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("DelaGothicOne-Regular", size: 14))
                .foregroundColor(isSelected ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color.black : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    VendorQuickProfileView()
}

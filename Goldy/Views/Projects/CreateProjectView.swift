//
//  CreateProjectView.swift
//  Goldy
//
//  Created by Blair Myers on 11/20/25.
//

import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProjectsViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var budget = ""
    @State private var eventDate = Date().addingTimeInterval(60 * 60 * 24 * 90)
    @State private var location = ""
    @State private var pinterestBoard = ""
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, description, budget, location, pinterest
    }
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create New Project")
                            .font(.custom("DelaGothicOne-Regular", size: 28))
                        
                        Text("Start planning your event by adding the basic details")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("PROJECT NAME", systemImage: "folder.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            TextField("e.g., Sarah & Mike's Wedding", text: $title)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .focused($focusedField, equals: .title)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("EVENT DATE", systemImage: "calendar")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            DatePicker(
                                "",
                                selection: $eventDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("LOCATION", systemImage: "location.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            TextField("e.g., Detroit, MI", text: $location)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .focused($focusedField, equals: .location)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("TOTAL BUDGET", systemImage: "dollarsign.circle.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                Text("OPTIONAL")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            
                            HStack(spacing: 12) {
                                Text("$")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                TextField("5000", text: $budget)
                                    .font(.system(size: 16))
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .budget)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("DESCRIPTION", systemImage: "text.alignleft")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                Text("OPTIONAL")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Describe your vision, style preferences, or any important notes for vendors...")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $description)
                                    .font(.system(size: 16))
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .focused($focusedField, equals: .description)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("PINTEREST BOARD", systemImage: "link")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                Text("OPTIONAL")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            
                            TextField("https://pinterest.com/...", text: $pinterestBoard)
                                .font(.system(size: 16))
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .focused($focusedField, equals: .pinterest)
                            
                            Text("Share your inspiration board to help vendors understand your style")
                                .font(.system(size: 11))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 4)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(hex: "E9D5FF"))
                                .font(.system(size: 20))
                            
                            Text("You'll be able to add vendors and set individual budgets after creating your project")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "E9D5FF").opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Button(action: { Task { await createProject() } }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("CREATE PROJECT")
                                    .font(.custom("DelaGothicOne-Regular", size: 14))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid && !isSubmitting ? Color.black : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color("Background"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
        }
    }
    
    private func createProject() async {
        guard isFormValid else { return }
        
        isSubmitting = true
        errorMessage = nil
        focusedField = nil
        
        do {
            let budgetCents: Int? = {
                guard !budget.isEmpty,
                      let dollars = Double(budget.filter { $0.isNumber || $0 == "." }) else {
                    return nil
                }
                return Int(dollars * 100)
            }()
            
            let validPinterestBoard: String? = {
                guard !pinterestBoard.trimmingCharacters(in: .whitespaces).isEmpty else {
                    return nil
                }
                let trimmed = pinterestBoard.trimmingCharacters(in: .whitespaces)
                if trimmed.starts(with: "http://") || trimmed.starts(with: "https://") {
                    return trimmed
                }
                return "https://\(trimmed)"
            }()
            
            try await viewModel.createProject(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
                totalBudget: budgetCents,
                eventDate: eventDate,
                location: location.isEmpty ? nil : location.trimmingCharacters(in: .whitespaces),
                pinterestBoard: validPinterestBoard
            )
            
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isSubmitting = false
        }
    }
}

#Preview {
    CreateProjectView(viewModel: ProjectsViewModel())
}

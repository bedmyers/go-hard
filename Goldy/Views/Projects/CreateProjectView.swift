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
    @State private var inspirationLink = ""
    @State private var eventType = ""
    @State private var isOtherEventType = false
    @State private var customEventType = ""

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showValidationMessage = false

    @FocusState private var focusedField: Field?

    enum Field {
        case title, description, budget, location, inspiration, customEventType
    }

    let eventTypes = ["Wedding", "Engagement Party", "Birthday", "Corporate Event", "Other"]

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Project name is required"
        }
        return nil
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
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("PROJECT NAME", systemImage: "folder.fill")
                                .font(.custom("Spectral-Bold", size: 11))
                                .foregroundColor(.gray)
                            
                            TextField("e.g., Sarah & Mike's Wedding", text: $title)
                                .font(.custom("Spectral-Regular", size: 16))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                                                .focused($focusedField, equals: .title)
                        }
                        
                        // Event Type
                        VStack(alignment: .leading, spacing: 8) {
                            Label("EVENT TYPE", systemImage: "sparkles")
                                .font(.custom("Spectral-Bold", size: 11))
                                .foregroundColor(.gray)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(eventTypes.dropLast(), id: \.self) { type in
                                        Button {
                                            isOtherEventType = false
                                            eventType = type
                                        } label: {
                                            Text(type)
                                                .font(.custom("Spectral-Medium", size: 13))
                                                .foregroundColor(eventType == type && !isOtherEventType ? .white : .black)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(eventType == type && !isOtherEventType ? Color.black : Color.white)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.gray.opacity(0.2), lineWidth: eventType == type && !isOtherEventType ? 0 : 1)
                                                )
                                        }
                                    }

                                    // Other button
                                    Button {
                                        isOtherEventType = true
                                        eventType = customEventType
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            focusedField = .customEventType
                                        }
                                    } label: {
                                        Text("Other")
                                            .font(.custom("Spectral-Medium", size: 13))
                                            .foregroundColor(isOtherEventType ? .white : .black)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(isOtherEventType ? Color.black : Color.white)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: isOtherEventType ? 0 : 1)
                                            )
                                    }
                                }
                            }

                            // Custom event type field
                            if isOtherEventType {
                                TextField("Enter event type...", text: $customEventType)
                                    .font(.custom("Spectral-Regular", size: 16))
                                    .focused($focusedField, equals: .customEventType)
                                    .onChange(of: customEventType) { _, newValue in
                                        eventType = newValue
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                                                }
                        }

                        // Event Date - left aligned
                        VStack(alignment: .leading, spacing: 8) {
                            Label("EVENT DATE", systemImage: "calendar")
                                .font(.custom("Spectral-Bold", size: 11))
                                .foregroundColor(.gray)

                            HStack {
                                DatePicker(
                                    "",
                                    selection: $eventDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()

                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                                                    }

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("LOCATION", systemImage: "location.fill")
                                    .font(.custom("Spectral-Bold", size: 11))
                                    .foregroundColor(.gray)

                                Text("OPTIONAL")
                                    .font(.custom("Spectral-Bold", size: 9))
                                    .foregroundColor(.gray.opacity(0.6))
                            }

                            TextField("e.g., Detroit, MI", text: $location)
                                .font(.custom("Spectral-Regular", size: 16))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                                                .focused($focusedField, equals: .location)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("TOTAL BUDGET", systemImage: "dollarsign.circle.fill")
                                    .font(.custom("Spectral-Bold", size: 11))
                                    .foregroundColor(.gray)
                                
                                Text("OPTIONAL")
                                    .font(.custom("Spectral-Bold", size: 9))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                            
                            HStack(spacing: 12) {
                                Text("$")
                                    .font(.custom("Spectral-Medium", size: 18))
                                    .foregroundColor(.gray)
                                
                                TextField("5000", text: $budget)
                                    .font(.custom("Spectral-Regular", size: 16))
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .budget)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                                                    }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("DESCRIPTION", systemImage: "text.alignleft")
                                    .font(.custom("Spectral-Bold", size: 11))
                                    .foregroundColor(.gray)

                                Text("OPTIONAL")
                                    .font(.custom("Spectral-Bold", size: 9))
                                    .foregroundColor(.gray.opacity(0.6))
                            }

                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Describe your vision, style preferences, or any important notes...")
                                        .font(.custom("Spectral-Regular", size: 16))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $description)
                                    .font(.custom("Spectral-Regular", size: 16))
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .focused($focusedField, equals: .description)
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            Text("Visible to vendors you invite")
                                .font(.custom("Spectral-Regular", size: 11))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 4)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("INSPIRATION LINK", systemImage: "link")
                                    .font(.custom("Spectral-Bold", size: 11))
                                    .foregroundColor(.gray)

                                Text("OPTIONAL")
                                    .font(.custom("Spectral-Bold", size: 9))
                                    .foregroundColor(.gray.opacity(0.6))
                            }

                            TextField("Pinterest, mood board, or reference link...", text: $inspirationLink)
                                .font(.custom("Spectral-Regular", size: 16))
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                                                .focused($focusedField, equals: .inspiration)

                            Text("Share your inspiration to help vendors understand your style")
                                .font(.custom("Spectral-Regular", size: 11))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.horizontal, 4)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(hex: "E9D5FF"))
                                .font(.custom("Spectral-Regular", size: 20))
                            
                            Text("You'll be able to add vendors and set individual budgets after creating your project")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "E9D5FF").opacity(0.2))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Validation message
                    if showValidationMessage, let message = validationMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(Color(hex: "EF4444"))
                            Text(message)
                                .font(.custom("Spectral-Medium", size: 13))
                                .foregroundColor(Color(hex: "EF4444"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Button(action: {
                        if isFormValid {
                            Task { await createProject() }
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showValidationMessage = true
                            }
                            // Hide after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showValidationMessage = false
                                }
                            }
                        }
                    }) {
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

            let validInspirationLink: String? = {
                guard !inspirationLink.trimmingCharacters(in: .whitespaces).isEmpty else {
                    return nil
                }
                let trimmed = inspirationLink.trimmingCharacters(in: .whitespaces)
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
                pinterestBoard: validInspirationLink // Still using pinterestBoard param for API compatibility
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

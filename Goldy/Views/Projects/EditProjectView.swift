//
//  EditProjectView.swift
//  Goldy
//
//  Created by Blair Myers on 12/30/25.
//

import SwiftUI

struct EditProjectView: View {
    @Environment(\.dismiss) var dismiss
    let project: Project

    @State private var title: String
    @State private var budget: String
    @State private var eventDate: Date
    @State private var location: String

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(project: Project) {
        self.project = project
        _title = State(initialValue: project.title)
        _budget = State(initialValue: project.totalBudgetDollars.map { String(Int($0)) } ?? "")
        _eventDate = State(initialValue: project.eventDate ?? Date())
        _location = State(initialValue: project.location ?? "")
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
                        Text("Edit Project")
                            .font(.system(size: 28, weight: .bold))

                        Text("Update your project details")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    VStack(spacing: 20) {
                        // Project Name
                        VStack(alignment: .leading, spacing: 8) {
                            Label("PROJECT NAME", systemImage: "folder.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)

                            TextField("Project name", text: $title)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }

                        // Event Date
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

                        // Location
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
                        }

                        // Budget
                        VStack(alignment: .leading, spacing: 8) {
                            Label("TOTAL BUDGET", systemImage: "dollarsign.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)

                            HStack(spacing: 12) {
                                Text("$")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)

                                TextField("5000", text: $budget)
                                    .font(.system(size: 16))
                                    .keyboardType(.numberPad)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)

                    // Save Button
                    Button(action: { Task { await saveChanges() } }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("SAVE CHANGES")
                                    .font(.system(size: 14, weight: .semibold))
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

    private func saveChanges() async {
        guard isFormValid else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            let budgetCents: Int? = {
                guard !budget.isEmpty,
                      let dollars = Double(budget.filter { $0.isNumber || $0 == "." }) else {
                    return nil
                }
                return Int(dollars * 100)
            }()

            var body: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespaces)
            ]

            // Format date as ISO string
            let formatter = ISO8601DateFormatter()
            body["eventDate"] = formatter.string(from: eventDate)

            if !location.trimmingCharacters(in: .whitespaces).isEmpty {
                body["location"] = location.trimmingCharacters(in: .whitespaces)
            }

            if let budgetCents = budgetCents {
                body["totalBudget"] = budgetCents
            }

            _ = try await APIService.shared.updateProject(
                projectId: project.id,
                body: body
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
    EditProjectView(
        project: Project(
            id: 1,
            title: "Test Project",
            description: nil,
            totalBudget: 500000,
            eventDate: Date(),
            location: "Detroit, MI",
            pinterestBoard: nil,
            status: .active,
            customerId: 1,
            customer: User(id: 1, email: "test@test.com", name: "Test", userType: .customer),
            vendors: [],
            createdAt: Date(),
            updatedAt: Date(),
            myVendorRole: nil
        )
    )
}

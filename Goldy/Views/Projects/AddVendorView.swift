//
//  AddVendorView.swift
//  Goldy
//
//  Created by Blair Myers on 11/25/25.
//

import SwiftUI

struct AddVendorView: View {
    let project: Project
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AddVendorViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressHeader(currentStep: viewModel.currentStep)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Step content
                TabView(selection: $viewModel.currentStep) {
                    VendorInfoStep(viewModel: viewModel)
                        .tag(AddVendorStep.vendorInfo)
                    
                    PaymentSetupStep(viewModel: viewModel)
                        .tag(AddVendorStep.paymentSetup)
                    
                    TermsStep(viewModel: viewModel)
                        .tag(AddVendorStep.terms)
                    
                    ReviewStep(viewModel: viewModel, project: project)
                        .tag(AddVendorStep.review)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                
                // Bottom navigation
                bottomNavigation
            }
            .background(Color("Background"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isSubmitting)
                }
            }
            .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error)
            }
            .onChange(of: viewModel.didComplete) { completed in
                if completed { dismiss() }
            }
        }
    }
    
    private var bottomNavigation: some View {
        HStack(spacing: 12) {
            // Back button
            if viewModel.currentStep != .vendorInfo {
                Button {
                    viewModel.goBack()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Next/Submit button
            Button {
                if viewModel.currentStep == .review {
                    Task { await viewModel.submitVendor(projectId: project.id) }
                } else {
                    viewModel.goNext()
                }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Text(viewModel.currentStep == .review ? "SEND AGREEMENT" : "CONTINUE")
                            .font(.custom("DelaGothicOne-Regular", size: 13))
                        
                        if viewModel.currentStep != .review {
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.canProceed ? Color.black : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canProceed || viewModel.isSubmitting)
        }
        .padding()
        .background(Color("Background"))
    }
}

// MARK: - Progress Header

private struct ProgressHeader: View {
    let currentStep: AddVendorStep
    
    var body: some View {
        VStack(spacing: 12) {
            // Step indicators
            HStack(spacing: 8) {
                ForEach(AddVendorStep.allCases, id: \.self) { step in
                    StepIndicator(
                        step: step,
                        isActive: step == currentStep,
                        isCompleted: step.rawValue < currentStep.rawValue
                    )
                }
            }
            
            // Step title
            Text(currentStep.title)
                .font(.custom("DelaGothicOne-Regular", size: 22))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(currentStep.subtitle)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 8)
    }
}

private struct StepIndicator: View {
    let step: AddVendorStep
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? Color.black : (isCompleted ? Color(hex: "BBF7D0") : Color.gray.opacity(0.3)))
                .frame(height: 4)
            
            Text(step.shortTitle)
                .font(.system(size: 9, weight: isActive ? .semibold : .medium))
                .foregroundColor(isActive ? .black : .gray)
        }
    }
}

// MARK: - Step 1: Vendor Info

private struct VendorInfoStep: View {
    @ObservedObject var viewModel: AddVendorViewModel
    @FocusState private var focusedField: Field?
    
    enum Field { case name, email }
    
    let vendorRoles = [
        "Venue", "Catering", "Photography", "Videography",
        "Florals", "Music/DJ", "Wedding Planner", "Hair & Makeup",
        "Cake/Desserts", "Transportation", "Rentals", "Other"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Vendor Name
                VStack(alignment: .leading, spacing: 8) {
                    Label("VENDOR NAME", systemImage: "building.2.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    TextField("e.g., Bella Vista Events", text: $viewModel.vendorName)
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .focused($focusedField, equals: .name)
                }
                
                // Vendor Email
                VStack(alignment: .leading, spacing: 8) {
                    Label("VENDOR EMAIL", systemImage: "envelope.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    TextField("vendor@example.com", text: $viewModel.vendorEmail)
                        .font(.system(size: 16))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .focused($focusedField, equals: .email)
                    
                    Text("We'll send them an invite to accept the agreement")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                // Role Selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("SERVICE TYPE", systemImage: "tag.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(vendorRoles, id: \.self) { role in
                            RoleChip(
                                role: role,
                                isSelected: viewModel.vendorRole == role
                            ) {
                                viewModel.vendorRole = role
                            }
                        }
                    }
                }
                
                // Description (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("NOTES", systemImage: "text.alignleft")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text("OPTIONAL")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    TextField("Any specific details about this vendor...", text: $viewModel.vendorDescription, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(3...5)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

private struct RoleChip: View {
    let role: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(role)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.black : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Step 2: Payment Setup

private struct PaymentSetupStep: View {
    @ObservedObject var viewModel: AddVendorViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Total Amount
                VStack(alignment: .leading, spacing: 8) {
                    Label("TOTAL AMOUNT", systemImage: "dollarsign.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Text("$")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("0", text: $viewModel.totalAmount)
                            .font(.custom("DelaGothicOne-Regular", size: 24))
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                // Milestones
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("PAYMENT MILESTONES", systemImage: "flag.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button {
                            viewModel.addMilestone()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "E9D5FF"))
                            .cornerRadius(6)
                        }
                    }
                    
                    if viewModel.milestones.isEmpty {
                        emptyMilestonesHint
                    } else {
                        ForEach(viewModel.milestones.indices, id: \.self) { index in
                            MilestoneCard(
                                milestone: $viewModel.milestones[index],
                                index: index,
                                onDelete: {
                                    viewModel.removeMilestone(at: index)
                                }
                            )
                        }
                        
                        // Milestone total check
                        milestoneTotalIndicator
                    }
                }
                
                // Quick templates
                VStack(alignment: .leading, spacing: 12) {
                    Text("QUICK TEMPLATES")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 10) {
                        TemplateButton(title: "50/50 Split") {
                            viewModel.applyTemplate(.fiftyFifty)
                        }
                        
                        TemplateButton(title: "30/30/40") {
                            viewModel.applyTemplate(.thirtyThirtyForty)
                        }
                        
                        TemplateButton(title: "Deposit + Final") {
                            viewModel.applyTemplate(.depositFinal)
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var emptyMilestonesHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("Break payments into milestones")
                .font(.system(size: 14, weight: .medium))
            
            Text("e.g., deposit now, balance before event")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var milestoneTotalIndicator: some View {
        let milestoneTotal = viewModel.milestones.reduce(0) { $0 + (Int($1.amount) ?? 0) }
        let total = Int(viewModel.totalAmount) ?? 0
        let isMatched = milestoneTotal == total && total > 0
        let difference = total - milestoneTotal
        
        return HStack {
            Image(systemName: isMatched ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isMatched ? Color(hex: "22C55E") : Color(hex: "F59E0B"))
            
            if isMatched {
                Text("Milestones match total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "22C55E"))
            } else if difference > 0 {
                Text("$\(difference) remaining to allocate")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "F59E0B"))
            } else {
                Text("$\(abs(difference)) over total amount")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "EF4444"))
            }
            
            Spacer()
        }
        .padding(12)
        .background(isMatched ? Color(hex: "BBF7D0").opacity(0.3) : Color(hex: "FEF3C7"))
        .cornerRadius(8)
    }
}

private struct MilestoneCard: View {
    @Binding var milestone: MilestoneInput
    let index: Int
    let onDelete: () -> Void
    @State private var showDatePicker = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Milestone \(index + 1)")
                    .font(.system(size: 13, weight: .semibold))
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            // Amount
            HStack(spacing: 8) {
                Text("$")
                    .foregroundColor(.gray)
                TextField("Amount", text: $milestone.amount)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(12)
            .background(Color("Background"))
            .cornerRadius(8)
            
            // Description
            TextField("Description (e.g., Deposit)", text: $milestone.description)
                .font(.system(size: 14))
                .padding(12)
                .background(Color("Background"))
                .cornerRadius(8)
            
            // Due Date
            HStack {
                Text("Due Date")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { milestone.dueDate ?? Date() },
                        set: { milestone.dueDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
            }
            .padding(12)
            .background(Color("Background"))
            .cornerRadius(8)
            
            // Release Condition
            TextField("Release condition (e.g., After venue walkthrough)", text: $milestone.releaseCondition)
                .font(.system(size: 14))
                .padding(12)
                .background(Color("Background"))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct TemplateButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Step 3: Terms

private struct TermsStep: View {
    @ObservedObject var viewModel: AddVendorViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // AI generation indicator
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(hex: "8B5CF6"))
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-Generated Terms")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Based on your vendor type and payment schedule")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(hex: "E9D5FF").opacity(0.3))
                .cornerRadius(12)
                
                // Terms sections
                ForEach(viewModel.termsSections.indices, id: \.self) { index in
                    TermsSectionCard(section: $viewModel.termsSections[index])
                }
                
                // Disclaimer
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.gray)
                    
                    Text("These terms are provided as a starting point. For large contracts, we recommend consulting with a legal professional.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .onAppear {
            viewModel.generateTerms()
        }
    }
}

private struct TermsSectionCard: View {
    @Binding var section: TermsSection
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Toggle("", isOn: $section.isEnabled)
                        .labelsHidden()
                        .scaleEffect(0.8)
                    
                    Text(section.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            // Content
            if isExpanded {
                Divider()
                
                TextEditor(text: $section.content)
                    .font(.system(size: 13))
                    .frame(minHeight: 100)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color("Background"))
                    .disabled(!section.isEnabled)
                    .opacity(section.isEnabled ? 1 : 0.5)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Step 4: Review

private struct ReviewStep: View {
    @ObservedObject var viewModel: AddVendorViewModel
    let project: Project
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Vendor Summary
                SummaryCard(title: "Vendor") {
                    SummaryRow(label: "Name", value: viewModel.vendorName)
                    SummaryRow(label: "Email", value: viewModel.vendorEmail)
                    SummaryRow(label: "Service", value: viewModel.vendorRole)
                }
                
                // Payment Summary
                SummaryCard(title: "Payment") {
                    SummaryRow(label: "Total Amount", value: "$\(viewModel.totalAmount)", isBold: true)
                    
                    Divider()
                    
                    ForEach(viewModel.milestones.indices, id: \.self) { index in
                        let milestone = viewModel.milestones[index]
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(milestone.description.isEmpty ? "Milestone \(index + 1)" : milestone.description)
                                    .font(.system(size: 13))
                                
                                if let date = milestone.dueDate {
                                    Text(date, style: .date)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Text("$\(milestone.amount)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Terms Summary
                SummaryCard(title: "Terms & Conditions") {
                    let enabledSections = viewModel.termsSections.filter { $0.isEnabled }
                    
                    ForEach(enabledSections.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "22C55E"))
                                .font(.system(size: 14))
                            
                            Text(enabledSections[index].title)
                                .font(.system(size: 13))
                        }
                    }
                }
                
                // What happens next
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHAT HAPPENS NEXT")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    TimelineItem(
                        icon: "envelope.fill",
                        title: "Vendor Invited",
                        description: "\(viewModel.vendorName) will receive an email to join Go Hard"
                    )
                    
                    TimelineItem(
                        icon: "checkmark.circle.fill",
                        title: "Vendor Accepts",
                        description: "They'll create an account and complete payment setup"
                    )
                    
                    TimelineItem(
                        icon: "lock.fill",
                        title: "Fund Escrow",
                        description: "Once they're set up, you can fund the first milestone"
                    )
                    
                    TimelineItem(
                        icon: "arrow.right.circle.fill",
                        title: "Release Payments",
                        description: "Release milestones as work is completed"
                    )
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

private struct SummaryCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(isBold ? .custom("DelaGothicOne-Regular", size: 16) : .system(size: 13, weight: .medium))
        }
    }
}

private struct TimelineItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "8B5CF6"))
                .font(.system(size: 16))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddVendorView(
        project: Project(
            id: 1,
            title: "Test Wedding",
            description: nil,
            totalBudget: nil,
            eventDate: nil,
            location: nil,
            pinterestBoard: nil,
            status: .planning,
            customerId: 1,
            customer: User(id: 1, email: "test@test.com", name: "Test", userType: User.UserType.customer),
            vendors: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}

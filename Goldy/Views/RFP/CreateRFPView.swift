//
//  CreateRFPView.swift
//  Goldy
//
//  Created by Blair Myers on 11/28/25.
//

import SwiftUI

struct CreateRFPView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateRFPViewModel()
    
    let projectId: Int?
    var onCreated: ((RFP) -> Void)?
    
    init(projectId: Int? = nil, onCreated: ((RFP) -> Void)? = nil) {
        self.projectId = projectId
        self.onCreated = onCreated
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    progressBar
                    
                    TabView(selection: $viewModel.currentStep) {
                        Step1BasicsView(viewModel: viewModel).tag(1)
                        Step2EventView(viewModel: viewModel).tag(2)
                        Step3StyleView(viewModel: viewModel).tag(3)
                        Step4RequirementsView(viewModel: viewModel).tag(4)
                        Step5BudgetView(viewModel: viewModel).tag(5)
                        Step6VisibilityView(viewModel: viewModel).tag(6)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: viewModel.currentStep)
                    
                    navigationButtons
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong")
            }
            .onChange(of: viewModel.didCreate) { created in
                if created, let rfp = viewModel.createdRFP {
                    onCreated?(rfp)
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(1...6, id: \.self) { step in
                Capsule()
                    .fill(step <= viewModel.currentStep ? Color(hex: "FFD700") : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private var stepTitle: String {
        switch viewModel.currentStep {
        case 1: return "What do you need?"
        case 2: return "Event Details"
        case 3: return "Style & Inspiration"
        case 4: return "Requirements"
        case 5: return "Budget & Timeline"
        case 6: return "Visibility"
        default: return "Create RFP"
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                if viewModel.currentStep > 1 {
                    Button {
                        withAnimation { viewModel.currentStep -= 1 }
                    } label: {
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Button {
                    if viewModel.currentStep < 6 {
                        withAnimation { viewModel.currentStep += 1 }
                    } else {
                        Task { await viewModel.createRFP(projectId: projectId) }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text(viewModel.currentStep < 6 ? "Continue" : "Post Request")
                                .font(.custom("DelaGothicOne-Regular", size: 14))
                            if viewModel.currentStep < 6 {
                                Image(systemName: "arrow.right")
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "FFD700"))
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canProceed || viewModel.isLoading)
                .opacity(viewModel.canProceed ? 1.0 : 0.5)
            }
            .padding()
            .background(Color(hex: "F5F1E8"))
        }
    }
}

// MARK: - Step 1: Basics

private struct Step1BasicsView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "FFD700"))
                    
                    Text("Tell vendors what you're looking for")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(RFPCategory.allCases, id: \.self) { category in
                                CategoryPill(
                                    category: category,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.selectedCategory = category
                                    if viewModel.title.isEmpty {
                                        viewModel.title = "Looking for \(category.rawValue)"
                                    }
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("TITLE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    TextField("e.g., Wedding Photographer for June Wedding", text: $viewModel.title)
                        .font(.system(size: 15))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("DESCRIPTION")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    TextEditor(text: $viewModel.description)
                        .font(.system(size: 15))
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(10)
                    
                    Text("What style are you looking for? Any specific needs?")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - Category Pill

private struct CategoryPill: View {
    let category: RFPCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "FFD700") : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step 2: Event Details

private struct Step2EventView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Help vendors know if they're available")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("EVENT DATE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    DatePicker(
                        "",
                        selection: $viewModel.eventDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("LOCATION")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    TextField("e.g., Detroit, MI", text: $viewModel.location)
                        .font(.system(size: 15))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("GUEST COUNT")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    HStack {
                        TextField("e.g., 150", text: $viewModel.guestCountText)
                            .font(.system(size: 15))
                            .keyboardType(.numberPad)
                        Text("guests")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    HStack(spacing: 8) {
                        ForEach(["50", "100", "150", "200", "300"], id: \.self) { count in
                            Button {
                                viewModel.guestCountText = count
                            } label: {
                                Text(count)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(viewModel.guestCountText == count ? .black : .gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(viewModel.guestCountText == count ? Color(hex: "FFD700").opacity(0.3) : Color.white)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - Step 3: Style & Inspiration

private struct Step3StyleView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Share your vision with vendors")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("PINTEREST MOOD BOARD")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text("Optional")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.gray)
                        TextField("Paste Pinterest board URL", text: $viewModel.inspirationUrl)
                            .font(.system(size: 15))
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    Text("Share a link to your Pinterest board so vendors can see your style")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("STYLE TAGS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(StyleTag.allCases, id: \.self) { tag in
                            StyleTagPill(
                                tag: tag,
                                isSelected: viewModel.selectedStyleTags.contains(tag)
                            ) {
                                if viewModel.selectedStyleTags.contains(tag) {
                                    viewModel.selectedStyleTags.remove(tag)
                                } else {
                                    viewModel.selectedStyleTags.insert(tag)
                                }
                            }
                        }
                    }
                    
                    Text("Select all that apply")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - Style Tag Pill

private struct StyleTagPill: View {
    let tag: StyleTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: tag.icon)
                    .font(.system(size: 10))
                Text(tag.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "FFD700") : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step 4: Requirements

private struct Step4RequirementsView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("What's essential vs. nice-to-have?")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                // Must Haves
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(hex: "FF6B35"))
                        Text("MUST HAVES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("(up to 3)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            TextField(placeholders[index], text: binding(for: index, in: \.mustHaves))
                                .font(.system(size: 15))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                
                // Nice to Haves
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(hex: "22C55E"))
                        Text("NICE TO HAVES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        Text("(up to 3)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            TextField("Optional", text: binding(for: index, in: \.niceToHaves))
                                .font(.system(size: 15))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private var placeholders: [String] {
        ["e.g., Available on my date", "e.g., Experience with outdoor venues", "e.g., Specific equipment"]
    }
    
    private func binding(for index: Int, in keyPath: ReferenceWritableKeyPath<CreateRFPViewModel, [String]>) -> Binding<String> {
        Binding(
            get: {
                index < viewModel[keyPath: keyPath].count ? viewModel[keyPath: keyPath][index] : ""
            },
            set: { newValue in
                while viewModel[keyPath: keyPath].count <= index {
                    viewModel[keyPath: keyPath].append("")
                }
                viewModel[keyPath: keyPath][index] = newValue
            }
        )
    }
}

// MARK: - Step 5: Budget & Timeline

private struct Step5BudgetView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Set expectations for vendors")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                // Budget
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("BUDGET")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text("Optional")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("$")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gray)
                        TextField("e.g., 5000", text: $viewModel.budgetText)
                            .font(.system(size: 18))
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    // Quick budget buttons
                    HStack(spacing: 8) {
                        ForEach(["1000", "3000", "5000", "10000"], id: \.self) { amount in
                            Button {
                                viewModel.budgetText = amount
                            } label: {
                                Text("$\(Int(amount)!/1000)K")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(viewModel.budgetText == amount ? .black : .gray)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(viewModel.budgetText == amount ? Color(hex: "FFD700").opacity(0.3) : Color.white)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
                
                // Proposals Due
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROPOSALS DUE BY")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    DatePicker(
                        "",
                        selection: $viewModel.deadline,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                }
                
                // Decision Date
                VStack(alignment: .leading, spacing: 6) {
                    Text("WHEN WILL YOU DECIDE?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    DatePicker(
                        "",
                        selection: $viewModel.decisionDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    Text("Let vendors know when to expect your decision")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - Step 6: Visibility

private struct Step6VisibilityView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Who can see this request?")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                VStack(spacing: 12) {
                    VisibilityOption(
                        title: "Public",
                        description: "Any vendor can see and bid on this request",
                        icon: "globe",
                        isSelected: viewModel.visibility == .public
                    ) {
                        viewModel.visibility = .public
                    }
                    
                    VisibilityOption(
                        title: "Private",
                        description: "Only vendors you invite can see this request",
                        icon: "lock.fill",
                        isSelected: viewModel.visibility == .private
                    ) {
                        viewModel.visibility = .private
                    }
                }
                
                if viewModel.visibility == .private {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("INVITE VENDORS")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text("You can invite specific vendors after creating this request")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
                
                // Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("SUMMARY")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SummaryRow(label: "Title", value: viewModel.title)
                        SummaryRow(label: "Location", value: viewModel.location.isEmpty ? "Not specified" : viewModel.location)
                        SummaryRow(label: "Event Date", value: viewModel.eventDate.formatted(date: .abbreviated, time: .omitted))
                        SummaryRow(label: "Budget", value: viewModel.budgetText.isEmpty ? "Flexible" : "$\(viewModel.budgetText)")
                        SummaryRow(label: "Proposals Due", value: viewModel.deadline.formatted(date: .abbreviated, time: .omitted))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - Visibility Option

private struct VisibilityOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "FFD700") : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .black : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(hex: "22C55E") : .gray.opacity(0.3))
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "FFD700") : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Preview

#Preview {
    CreateRFPView()
}

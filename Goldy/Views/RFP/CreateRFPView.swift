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
    @State private var showSuccessScreen = false

    let projectId: Int?
    var onCreated: ((RFP) -> Void)?

    init(projectId: Int? = nil, onCreated: ((RFP) -> Void)? = nil) {
        self.projectId = projectId
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                if showSuccessScreen, let rfp = viewModel.createdRFP {
                    RFPSuccessView(rfp: rfp) {
                        onCreated?(rfp)
                        dismiss()
                    }
                } else {
                    VStack(spacing: 0) {
                        progressBar

                        TabView(selection: $viewModel.currentStep) {
                            Step1BasicsView(viewModel: viewModel).tag(1)
                            Step2EventView(viewModel: viewModel).tag(2)
                            Step3DetailsView(viewModel: viewModel).tag(3)
                            Step4BudgetView(viewModel: viewModel).tag(4)
                            Step5VisibilityView(viewModel: viewModel).tag(5)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut, value: viewModel.currentStep)

                        navigationButtons
                    }
                }
            }
            .navigationTitle(showSuccessScreen ? "" : stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showSuccessScreen {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong")
            }
            .onChange(of: viewModel.didCreate) { _, created in
                if created {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSuccessScreen = true
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { step in
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
        case 3: return "Style & Requirements"
        case 4: return "Budget & Timeline"
        case 5: return "Visibility"
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
                            .font(.custom("Spectral-Medium", size: 16))
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
                    if viewModel.currentStep < 5 {
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
                            Text(viewModel.currentStep < 5 ? "Continue" : "Post Request")
                                .font(.custom("DelaGothicOne-Regular", size: 14))
                            if viewModel.currentStep < 5 {
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
            .background(Color("Background"))
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
                        .font(.custom("Spectral-Regular", size: 40))
                        .foregroundColor(Color(hex: "FFD700"))
                    
                    Text("Tell vendors what you're looking for")
                        .font(.custom("Spectral-Regular", size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.custom("Spectral-Bold", size: 12))
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
                        .font(.custom("Spectral-Bold", size: 12))
                        .foregroundColor(.gray)
                    
                    TextField("e.g., Wedding Photographer for June Wedding", text: $viewModel.title)
                        .font(.custom("Spectral-Regular", size: 15))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("DESCRIPTION")
                        .font(.custom("Spectral-Bold", size: 12))
                        .foregroundColor(.gray)

                    ZStack(alignment: .topLeading) {
                        if viewModel.description.isEmpty {
                            Text("e.g., Looking for a photographer who specializes in candid shots and outdoor settings...")
                                .font(.custom("Spectral-Regular", size: 15))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $viewModel.description)
                            .font(.custom("Spectral-Regular", size: 15))
                            .frame(minHeight: 120)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                    }
                    .background(Color.white)
                    .cornerRadius(10)

                    Text("What style are you looking for? Any specific needs?")
                        .font(.custom("Spectral-Regular", size: 12))
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
                    .font(.custom("Spectral-Regular", size: 12))
                Text(category.rawValue)
                    .font(.custom("Spectral-Medium", size: 13))
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
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("EVENT DATE")
                        .font(.custom("Spectral-Bold", size: 12))
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

                // Time of Day
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("TIME OF DAY")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        Text("Optional")
                            .font(.custom("Spectral-Regular", size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    HStack(spacing: 8) {
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            Button {
                                if viewModel.selectedTimeOfDay == time {
                                    viewModel.selectedTimeOfDay = nil
                                } else {
                                    viewModel.selectedTimeOfDay = time
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: time.icon)
                                        .font(.system(size: 12))
                                    Text(time.rawValue)
                                        .font(.custom("Spectral-Medium", size: 12))
                                }
                                .foregroundColor(viewModel.selectedTimeOfDay == time ? .black : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(viewModel.selectedTimeOfDay == time ? Color(hex: "FFD700") : Color.white)
                                .cornerRadius(16)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("LOCATION")
                        .font(.custom("Spectral-Bold", size: 12))
                        .foregroundColor(.gray)
                    
                    TextField("e.g., Detroit, MI", text: $viewModel.location)
                        .font(.custom("Spectral-Regular", size: 15))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("GUEST COUNT")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        Text("Optional")
                            .font(.custom("Spectral-Regular", size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    HStack {
                        TextField("e.g., 150", text: $viewModel.guestCountText)
                            .font(.custom("Spectral-Regular", size: 15))
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
                                    .font(.custom("Spectral-Medium", size: 12))
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

// MARK: - Step 3: Style & Requirements (Combined)

private struct Step3DetailsView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    @State private var mustHaveCount: Int = 1
    @State private var niceToHaveCount: Int = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Share your vision and requirements")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                // MARK: Style Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("STYLE TAGS")
                        .font(.custom("Spectral-Bold", size: 12))
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
                        .font(.custom("Spectral-Regular", size: 12))
                        .foregroundColor(.gray)
                }

                // Inspiration Link
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("INSPIRATION LINK")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        Text("Optional")
                            .font(.custom("Spectral-Regular", size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.gray)
                        TextField("Pinterest, mood board, or reference...", text: $viewModel.inspirationUrl)
                            .font(.custom("Spectral-Regular", size: 15))
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }

                Divider().padding(.vertical, 8)

                // MARK: Requirements Section
                // Must Haves
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(hex: "FF6B35"))
                        Text("MUST HAVES")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)
                    }

                    ForEach(0..<mustHaveCount, id: \.self) { index in
                        HStack {
                            TextField(mustHavePlaceholders[index], text: binding(for: index, in: \.mustHaves))
                                .font(.custom("Spectral-Regular", size: 15))

                            if index > 0 {
                                Button {
                                    withAnimation {
                                        if index < viewModel.mustHaves.count {
                                            viewModel.mustHaves.remove(at: index)
                                        }
                                        mustHaveCount -= 1
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }

                    if mustHaveCount < 3 {
                        Button {
                            withAnimation {
                                mustHaveCount += 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add another")
                                    .font(.custom("Spectral-Medium", size: 13))
                            }
                            .foregroundColor(Color(hex: "FF6B35"))
                        }
                    }
                }

                // Nice to Haves
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(hex: "22C55E"))
                        Text("NICE TO HAVES")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        Text("Optional")
                            .font(.custom("Spectral-Regular", size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    ForEach(0..<niceToHaveCount, id: \.self) { index in
                        HStack {
                            TextField(niceToHavePlaceholders[index], text: binding(for: index, in: \.niceToHaves))
                                .font(.custom("Spectral-Regular", size: 15))

                            if index > 0 || niceToHaveCount > 1 {
                                Button {
                                    withAnimation {
                                        if index < viewModel.niceToHaves.count {
                                            viewModel.niceToHaves.remove(at: index)
                                        }
                                        niceToHaveCount -= 1
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }

                    if niceToHaveCount < 3 {
                        Button {
                            withAnimation {
                                niceToHaveCount += 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add another")
                                    .font(.custom("Spectral-Medium", size: 13))
                            }
                            .foregroundColor(Color(hex: "22C55E"))
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .onAppear {
            mustHaveCount = max(1, viewModel.mustHaves.filter { !$0.isEmpty }.count)
            niceToHaveCount = max(1, viewModel.niceToHaves.filter { !$0.isEmpty }.count)
        }
    }

    private var mustHavePlaceholders: [String] {
        ["e.g., Available on my date", "e.g., Experience with outdoor venues", "e.g., Specific equipment"]
    }

    private var niceToHavePlaceholders: [String] {
        ["e.g., Second shooter included", "e.g., Same-day previews", "e.g., Drone footage"]
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

// MARK: - Style Tag Pill

private struct StyleTagPill: View {
    let tag: StyleTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: tag.icon)
                    .font(.custom("Spectral-Regular", size: 10))
                Text(tag.displayName)
                    .font(.custom("Spectral-Medium", size: 12))
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

// MARK: - Step 4: Budget & Timeline

private struct Step4BudgetView: View {
    @ObservedObject var viewModel: CreateRFPViewModel

    private var isDecisionDateValid: Bool {
        viewModel.decisionDate >= viewModel.deadline
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Set expectations for vendors")
                    .font(.custom("Spectral-Regular", size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                // Budget
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("BUDGET")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        Text("Optional")
                            .font(.custom("Spectral-Regular", size: 10))
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    HStack {
                        Text("$")
                            .font(.custom("Spectral-Bold", size: 18))
                            .foregroundColor(.gray)
                        TextField("e.g., 5000", text: $viewModel.budgetText)
                            .font(.custom("Spectral-Regular", size: 18))
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
                                    .font(.custom("Spectral-Medium", size: 12))
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
                        .font(.custom("Spectral-Bold", size: 12))
                        .foregroundColor(.gray)

                    HStack {
                        DatePicker(
                            "",
                            selection: $viewModel.deadline,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()

                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .onChange(of: viewModel.deadline) { _, newDeadline in
                    // Auto-adjust decision date if it's before the new deadline
                    if viewModel.decisionDate < newDeadline {
                        viewModel.decisionDate = newDeadline.addingTimeInterval(60 * 60 * 24 * 7) // 1 week after
                    }
                }

                // Decision Date
                VStack(alignment: .leading, spacing: 6) {
                    Text("WHEN WILL YOU DECIDE?")
                        .font(.custom("Spectral-Bold", size: 12))
                        .foregroundColor(.gray)

                    HStack {
                        DatePicker(
                            "",
                            selection: $viewModel.decisionDate,
                            in: viewModel.deadline...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()

                        Spacer()
                    }
                    .padding()
                    .background(isDecisionDateValid ? Color.white : Color(hex: "FEE2E2"))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isDecisionDateValid ? Color.clear : Color(hex: "EF4444"), lineWidth: 1)
                    )

                    if !isDecisionDateValid {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Decision date must be after proposals due date")
                                .font(.custom("Spectral-Regular", size: 12))
                        }
                        .foregroundColor(Color(hex: "EF4444"))
                    } else {
                        Text("Let vendors know when to expect your decision")
                            .font(.custom("Spectral-Regular", size: 12))
                            .foregroundColor(.gray)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

// MARK: - Step 5: Visibility

private struct Step5VisibilityView: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    @State private var showPreview = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Who can see this request?")
                    .font(.custom("Spectral-Regular", size: 14))
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
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        Text("You can invite specific vendors after creating this request")
                            .font(.custom("Spectral-Regular", size: 13))
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }

                // Summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("SUMMARY")
                            .font(.custom("Spectral-Bold", size: 12))
                            .foregroundColor(.gray)

                        Spacer()

                        Button {
                            showPreview = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "eye")
                                Text("Preview")
                                    .font(.custom("Spectral-Medium", size: 12))
                            }
                            .foregroundColor(Color(hex: "8B5CF6"))
                        }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        // Basic Info
                        SummarySection(title: "Basic Info") {
                            SummaryRow(label: "Title", value: viewModel.title)
                            SummaryRow(label: "Category", value: viewModel.selectedCategory?.rawValue ?? "Not selected")
                            if !viewModel.description.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.custom("Spectral-Regular", size: 13))
                                        .foregroundColor(.gray)
                                    Text(viewModel.description)
                                        .font(.custom("Spectral-Regular", size: 13))
                                        .foregroundColor(.black)
                                        .lineLimit(3)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Divider().padding(.vertical, 8)

                        // Event Details
                        SummarySection(title: "Event Details") {
                            SummaryRow(label: "Date", value: viewModel.eventDate.formatted(date: .abbreviated, time: .omitted))
                            SummaryRow(label: "Location", value: viewModel.location.isEmpty ? "Not specified" : viewModel.location)
                            if !viewModel.guestCountText.isEmpty {
                                SummaryRow(label: "Guests", value: "\(viewModel.guestCountText) guests")
                            }
                        }

                        Divider().padding(.vertical, 8)

                        // Style
                        if !viewModel.selectedStyleTags.isEmpty || !viewModel.inspirationUrl.isEmpty {
                            SummarySection(title: "Style") {
                                if !viewModel.selectedStyleTags.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Style Tags")
                                            .font(.custom("Spectral-Regular", size: 13))
                                            .foregroundColor(.gray)
                                        Text(viewModel.selectedStyleTags.map { $0.displayName }.joined(separator: ", "))
                                            .font(.custom("Spectral-Medium", size: 13))
                                            .foregroundColor(.black)
                                    }
                                    .padding(.vertical, 2)
                                }
                                if !viewModel.inspirationUrl.isEmpty {
                                    SummaryRow(label: "Inspiration", value: "Link added ✓")
                                }
                            }
                            Divider().padding(.vertical, 8)
                        }

                        // Requirements
                        let mustHaves = viewModel.mustHaves.filter { !$0.isEmpty }
                        let niceToHaves = viewModel.niceToHaves.filter { !$0.isEmpty }
                        if !mustHaves.isEmpty || !niceToHaves.isEmpty {
                            SummarySection(title: "Requirements") {
                                if !mustHaves.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(hex: "FF6B35"))
                                            Text("Must Haves")
                                                .font(.custom("Spectral-Regular", size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        ForEach(mustHaves, id: \.self) { item in
                                            Text("• \(item)")
                                                .font(.custom("Spectral-Regular", size: 13))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                                if !niceToHaves.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(hex: "22C55E"))
                                            Text("Nice to Haves")
                                                .font(.custom("Spectral-Regular", size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        ForEach(niceToHaves, id: \.self) { item in
                                            Text("• \(item)")
                                                .font(.custom("Spectral-Regular", size: 13))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            Divider().padding(.vertical, 8)
                        }

                        // Budget & Timeline
                        SummarySection(title: "Budget & Timeline") {
                            SummaryRow(label: "Budget", value: viewModel.budgetText.isEmpty ? "Flexible" : "$\(viewModel.budgetText)")
                            SummaryRow(label: "Proposals Due", value: viewModel.deadline.formatted(date: .abbreviated, time: .omitted))
                            SummaryRow(label: "Decision By", value: viewModel.decisionDate.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showPreview) {
            RFPPreviewSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Summary Section

private struct SummarySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Spectral-Bold", size: 11))
                .foregroundColor(Color(hex: "8B5CF6"))

            content
        }
    }
}

// MARK: - RFP Preview Sheet

private struct RFPPreviewSheet: View {
    @ObservedObject var viewModel: CreateRFPViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let category = viewModel.selectedCategory {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 12))
                                    Text(category.rawValue)
                                        .font(.custom("Spectral-Medium", size: 12))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: "FFD700"))
                                .cornerRadius(12)
                            }

                            Spacer()

                            Text(viewModel.visibility == .public ? "Public" : "Private")
                                .font(.custom("Spectral-Regular", size: 12))
                                .foregroundColor(.gray)
                        }

                        Text(viewModel.title)
                            .font(.custom("DelaGothicOne-Regular", size: 22))

                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(viewModel.eventDate.formatted(date: .abbreviated, time: .omitted))
                            }
                            .font(.custom("Spectral-Regular", size: 13))
                            .foregroundColor(.gray)

                            if !viewModel.location.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "location")
                                    Text(viewModel.location)
                                }
                                .font(.custom("Spectral-Regular", size: 13))
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)

                    // Description
                    if !viewModel.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this request")
                                .font(.custom("Spectral-Bold", size: 14))

                            Text(viewModel.description)
                                .font(.custom("Spectral-Regular", size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                    }

                    // Event Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Details")
                            .font(.custom("Spectral-Bold", size: 14))

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(.custom("Spectral-Regular", size: 12))
                                    .foregroundColor(.gray)
                                Text(viewModel.eventDate.formatted(date: .long, time: .omitted))
                                    .font(.custom("Spectral-Medium", size: 14))
                            }

                            if !viewModel.guestCountText.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Guests")
                                        .font(.custom("Spectral-Regular", size: 12))
                                        .foregroundColor(.gray)
                                    Text(viewModel.guestCountText)
                                        .font(.custom("Spectral-Medium", size: 14))
                                }
                            }

                            if !viewModel.budgetText.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Budget")
                                        .font(.custom("Spectral-Regular", size: 12))
                                        .foregroundColor(.gray)
                                    Text("$\(viewModel.budgetText)")
                                        .font(.custom("Spectral-Medium", size: 14))
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)

                    // Requirements
                    let mustHaves = viewModel.mustHaves.filter { !$0.isEmpty }
                    let niceToHaves = viewModel.niceToHaves.filter { !$0.isEmpty }
                    if !mustHaves.isEmpty || !niceToHaves.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Requirements")
                                .font(.custom("Spectral-Bold", size: 14))

                            if !mustHaves.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(Color(hex: "FF6B35"))
                                        Text("Must Haves")
                                            .font(.custom("Spectral-Bold", size: 13))
                                    }
                                    ForEach(mustHaves, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "FF6B35"))
                                                .font(.system(size: 14))
                                            Text(item)
                                                .font(.custom("Spectral-Regular", size: 14))
                                        }
                                    }
                                }
                            }

                            if !niceToHaves.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(Color(hex: "22C55E"))
                                        Text("Nice to Haves")
                                            .font(.custom("Spectral-Bold", size: 13))
                                    }
                                    ForEach(niceToHaves, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(Color(hex: "22C55E"))
                                                .font(.system(size: 14))
                                            Text(item)
                                                .font(.custom("Spectral-Regular", size: 14))
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                    }

                    // Style Tags
                    if !viewModel.selectedStyleTags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Style")
                                .font(.custom("Spectral-Bold", size: 14))

                            FlowLayout(spacing: 8) {
                                ForEach(Array(viewModel.selectedStyleTags), id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Image(systemName: tag.icon)
                                            .font(.system(size: 10))
                                        Text(tag.displayName)
                                            .font(.custom("Spectral-Medium", size: 12))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(hex: "FFD700").opacity(0.3))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                    }

                    // Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Timeline")
                            .font(.custom("Spectral-Bold", size: 14))

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Proposals Due")
                                    .font(.custom("Spectral-Regular", size: 12))
                                    .foregroundColor(.gray)
                                Text(viewModel.deadline.formatted(date: .abbreviated, time: .omitted))
                                    .font(.custom("Spectral-Medium", size: 14))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Decision By")
                                    .font(.custom("Spectral-Regular", size: 12))
                                    .foregroundColor(.gray)
                                Text(viewModel.decisionDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.custom("Spectral-Medium", size: 14))
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Vendor Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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
                        .font(.custom("Spectral-Regular", size: 18))
                        .foregroundColor(isSelected ? .black : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Spectral-Bold", size: 16))
                        .foregroundColor(.black)
                    
                    Text(description)
                        .font(.custom("Spectral-Regular", size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.custom("Spectral-Regular", size: 24))
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
                .font(.custom("Spectral-Regular", size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.custom("Spectral-Medium", size: 13))
                .foregroundColor(.black)
        }
    }
}

// MARK: - RFP Success View

private struct RFPSuccessView: View {
    let rfp: RFP
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success animation
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "22C55E").opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color(hex: "22C55E").opacity(0.3))
                        .frame(width: 90, height: 90)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "22C55E"))
                }

                Text("Request Posted!")
                    .font(.custom("DelaGothicOne-Regular", size: 24))

                Text("Your request is now live and vendors can start submitting proposals")
                    .font(.custom("Spectral-Regular", size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Info cards
            VStack(spacing: 12) {
                InfoCard(
                    icon: "magnifyingglass",
                    iconColor: Color(hex: "8B5CF6"),
                    title: "Find Your Request",
                    description: "Go to your project and tap \"RFPs\" to view and manage this request"
                )

                InfoCard(
                    icon: "bell.badge",
                    iconColor: Color(hex: "FF6B35"),
                    title: "Get Notified",
                    description: "You'll receive notifications when vendors submit proposals"
                )

                InfoCard(
                    icon: "pencil",
                    iconColor: Color(hex: "3B82F6"),
                    title: "Need to Edit?",
                    description: "You can edit your request anytime from the RFP details page"
                )
            }
            .padding(.horizontal)

            Spacer()

            // Done button
            Button(action: onDone) {
                Text("DONE")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "FFD700"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Info Card

private struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Spectral-Bold", size: 14))
                    .foregroundColor(.black)

                Text(description)
                    .font(.custom("Spectral-Regular", size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    CreateRFPView()
}

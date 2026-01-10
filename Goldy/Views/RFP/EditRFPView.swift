//
//  EditRFPView.swift
//  Goldy
//
//  Created by Blair Myers on 1/5/26.
//

import SwiftUI

struct EditRFPView: View {
    @Environment(\.dismiss) var dismiss

    let rfp: RFP
    var onUpdate: (RFP) -> Void

    // Form state
    @State private var title: String
    @State private var description: String
    @State private var budgetText: String
    @State private var eventDate: Date
    @State private var location: String
    @State private var guestCountText: String
    @State private var inspirationUrl: String
    @State private var selectedStyleTags: Set<StyleTag>
    @State private var mustHaves: [String]
    @State private var niceToHaves: [String]
    @State private var deadline: Date
    @State private var decisionDate: Date

    // UI state
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var mustHaveCount: Int
    @State private var niceToHaveCount: Int

    @FocusState private var focusedField: Field?

    enum Field {
        case title, description, budget, location, guestCount, inspiration
        case mustHave0, mustHave1, mustHave2
        case niceToHave0, niceToHave1, niceToHave2
    }

    init(rfp: RFP, onUpdate: @escaping (RFP) -> Void) {
        self.rfp = rfp
        self.onUpdate = onUpdate

        // Initialize state from RFP
        _title = State(initialValue: rfp.title)
        _description = State(initialValue: rfp.description)
        _budgetText = State(initialValue: rfp.budget != nil ? "\(rfp.budget! / 100)" : "")
        _eventDate = State(initialValue: rfp.eventDate ?? Date().addingTimeInterval(86400 * 180))
        _location = State(initialValue: rfp.location ?? "")
        _guestCountText = State(initialValue: rfp.guestCount != nil ? "\(rfp.guestCount!)" : "")
        _inspirationUrl = State(initialValue: rfp.inspirationUrl ?? "")

        // Convert style tag strings to StyleTag enum
        let tags: Set<StyleTag> = Set(rfp.styleTags?.compactMap { StyleTag(rawValue: $0) } ?? [])
        _selectedStyleTags = State(initialValue: tags)

        // Initialize must haves with existing values padded to 3
        var mh = rfp.mustHaves ?? []
        while mh.count < 3 { mh.append("") }
        _mustHaves = State(initialValue: Array(mh.prefix(3)))
        _mustHaveCount = State(initialValue: max(1, rfp.mustHaves?.filter { !$0.isEmpty }.count ?? 1))

        // Initialize nice to haves with existing values padded to 3
        var nth = rfp.niceToHaves ?? []
        while nth.count < 3 { nth.append("") }
        _niceToHaves = State(initialValue: Array(nth.prefix(3)))
        _niceToHaveCount = State(initialValue: max(1, rfp.niceToHaves?.filter { !$0.isEmpty }.count ?? 1))

        _deadline = State(initialValue: rfp.deadline ?? Date().addingTimeInterval(86400 * 14))
        _decisionDate = State(initialValue: rfp.decisionDate ?? Date().addingTimeInterval(86400 * 21))
    }

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit Request")
                            .font(.custom("DelaGothicOne-Regular", size: 24))

                        Text("Update your request details")
                            .font(.custom("Spectral-Regular", size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Basic Info
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("BASIC INFO")

                        formField("TITLE", systemImage: "tag.fill") {
                            TextField("What do you need?", text: $title)
                                .font(.custom("Spectral-Regular", size: 16))
                                .focused($focusedField, equals: .title)
                        }

                        formField("DESCRIPTION", systemImage: "text.alignleft") {
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Describe what you're looking for...")
                                        .font(.custom("Spectral-Regular", size: 16))
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $description)
                                    .font(.custom("Spectral-Regular", size: 16))
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .focused($focusedField, equals: .description)
                            }
                        }
                    }

                    // Event Details
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("EVENT DETAILS")

                        formField("LOCATION", systemImage: "location.fill") {
                            TextField("City, State", text: $location)
                                .font(.custom("Spectral-Regular", size: 16))
                                .focused($focusedField, equals: .location)
                        }

                        formField("EVENT DATE", systemImage: "calendar") {
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
                        }

                        formField("GUEST COUNT", systemImage: "person.2.fill", isOptional: true) {
                            TextField("e.g., 150", text: $guestCountText)
                                .font(.custom("Spectral-Regular", size: 16))
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .guestCount)
                        }
                    }

                    // Style & Inspiration
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("STYLE & INSPIRATION")

                        formField("INSPIRATION LINK", systemImage: "link", isOptional: true) {
                            TextField("Pinterest, mood board, or reference link...", text: $inspirationUrl)
                                .font(.custom("Spectral-Regular", size: 16))
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .inspiration)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("STYLE TAGS", systemImage: "sparkles")
                                    .font(.custom("Spectral-Bold", size: 11))
                                    .foregroundColor(.gray)

                                Text("OPTIONAL")
                                    .font(.custom("Spectral-Bold", size: 9))
                                    .foregroundColor(.gray.opacity(0.6))
                            }

                            FlowLayout(spacing: 8) {
                                ForEach(StyleTag.allCases, id: \.self) { tag in
                                    Button {
                                        if selectedStyleTags.contains(tag) {
                                            selectedStyleTags.remove(tag)
                                        } else {
                                            selectedStyleTags.insert(tag)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: tag.icon)
                                                .font(.system(size: 10))
                                            Text(tag.displayName)
                                                .font(.custom("Spectral-Medium", size: 12))
                                        }
                                        .foregroundColor(selectedStyleTags.contains(tag) ? .white : .black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedStyleTags.contains(tag) ? Color.black : Color.white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: selectedStyleTags.contains(tag) ? 0 : 1)
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Requirements
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("REQUIREMENTS")

                        requirementsSection(
                            title: "MUST HAVES",
                            icon: "checkmark.circle.fill",
                            items: $mustHaves,
                            count: $mustHaveCount,
                            fields: [.mustHave0, .mustHave1, .mustHave2]
                        )

                        requirementsSection(
                            title: "NICE TO HAVES",
                            icon: "star.fill",
                            items: $niceToHaves,
                            count: $niceToHaveCount,
                            fields: [.niceToHave0, .niceToHave1, .niceToHave2]
                        )
                    }

                    // Budget & Timeline
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("BUDGET & TIMELINE")

                        formField("BUDGET", systemImage: "dollarsign.circle.fill", isOptional: true) {
                            HStack(spacing: 8) {
                                Text("$")
                                    .font(.custom("Spectral-Medium", size: 18))
                                    .foregroundColor(.gray)

                                TextField("5000", text: $budgetText)
                                    .font(.custom("Spectral-Regular", size: 16))
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .budget)
                            }
                        }

                        formField("PROPOSALS DUE", systemImage: "clock.fill") {
                            HStack {
                                DatePicker(
                                    "",
                                    selection: $deadline,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .onChange(of: deadline) { _, newDeadline in
                                    if decisionDate < newDeadline {
                                        decisionDate = newDeadline.addingTimeInterval(60 * 60 * 24 * 7)
                                    }
                                }

                                Spacer()
                            }
                        }

                        formField("DECISION BY", systemImage: "calendar.badge.checkmark") {
                            HStack {
                                DatePicker(
                                    "",
                                    selection: $decisionDate,
                                    in: deadline...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()

                                Spacer()
                            }
                        }
                    }

                    // Save Button
                    Button {
                        Task { await saveChanges() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("SAVE CHANGES")
                                    .font(.custom("DelaGothicOne-Regular", size: 14))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid && !isLoading ? Color.black : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Something went wrong")
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom("DelaGothicOne-Regular", size: 14))
            .foregroundColor(.black)
    }

    private func formField<Content: View>(
        _ title: String,
        systemImage: String,
        isOptional: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.custom("Spectral-Bold", size: 11))
                    .foregroundColor(.gray)

                if isOptional {
                    Text("OPTIONAL")
                        .font(.custom("Spectral-Bold", size: 9))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }

            content()
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    private func requirementsSection(
        title: String,
        icon: String,
        items: Binding<[String]>,
        count: Binding<Int>,
        fields: [Field]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.custom("Spectral-Bold", size: 11))
                    .foregroundColor(.gray)

                Text("OPTIONAL")
                    .font(.custom("Spectral-Bold", size: 9))
                    .foregroundColor(.gray.opacity(0.6))
            }

            VStack(spacing: 10) {
                ForEach(0..<count.wrappedValue, id: \.self) { index in
                    HStack {
                        TextField("e.g., Available on my date", text: items[index])
                            .font(.custom("Spectral-Regular", size: 16))
                            .focused($focusedField, equals: fields[index])

                        if count.wrappedValue > 1 {
                            Button {
                                withAnimation {
                                    items.wrappedValue.remove(at: index)
                                    items.wrappedValue.append("")
                                    count.wrappedValue -= 1
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                if count.wrappedValue < 3 {
                    Button {
                        withAnimation {
                            count.wrappedValue += 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add another")
                        }
                        .font(.custom("Spectral-Medium", size: 13))
                        .foregroundColor(Color(hex: "FF6B35"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Save Changes

    private func saveChanges() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil
        focusedField = nil

        do {
            var body: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespaces),
                "description": description.trimmingCharacters(in: .whitespaces)
            ]

            // Event details
            body["eventDate"] = ISO8601DateFormatter().string(from: eventDate)

            if !location.isEmpty {
                body["location"] = location.trimmingCharacters(in: .whitespaces)
            }

            if let guestCount = Int(guestCountText), guestCount > 0 {
                body["guestCount"] = guestCount
            }

            // Style & inspiration
            if !inspirationUrl.isEmpty {
                body["inspirationUrl"] = inspirationUrl.trimmingCharacters(in: .whitespaces)
            }

            if !selectedStyleTags.isEmpty {
                body["styleTags"] = selectedStyleTags.map { $0.rawValue }
            }

            // Requirements
            let filteredMustHaves = mustHaves.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if !filteredMustHaves.isEmpty {
                body["mustHaves"] = filteredMustHaves
            }

            let filteredNiceToHaves = niceToHaves.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if !filteredNiceToHaves.isEmpty {
                body["niceToHaves"] = filteredNiceToHaves
            }

            // Budget & timeline
            if let budget = Int(budgetText.replacingOccurrences(of: ",", with: "")), budget > 0 {
                body["budget"] = budget * 100
            }

            body["deadline"] = ISO8601DateFormatter().string(from: deadline)
            body["decisionDate"] = ISO8601DateFormatter().string(from: decisionDate)

            let updatedRFP = try await APIService.shared.updateRFP(rfpId: rfp.id, body: body)

            print("✅ RFP updated: \(updatedRFP.id)")

            onUpdate(updatedRFP)
            dismiss()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error updating RFP: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    EditRFPView(rfp: RFP(
        id: 1,
        projectId: 1,
        customerId: 1,
        title: "Wedding Photographer Needed",
        description: "Looking for an experienced wedding photographer for our June 2025 wedding.",
        budget: 500000,
        deadline: Date().addingTimeInterval(86400 * 14),
        status: .open,
        eventDate: Date().addingTimeInterval(86400 * 180),
        location: "Detroit, MI",
        guestCount: 150,
        inspirationUrl: nil,
        styleTags: ["natural-light", "romantic"],
        mustHaves: ["Available on date", "Second shooter"],
        niceToHaves: ["Drone footage"],
        decisionDate: Date().addingTimeInterval(86400 * 21),
        visibility: .public,
        invitedVendorIds: nil,
        bids: [],
        customer: nil,
        project: nil,
        createdAt: Date(),
        updatedAt: Date()
    )) { _ in }
}

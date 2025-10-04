//
//  FillOutEscrowView.swift
//  Goldy
//
//  Created by Blair Myers on 6/6/25.
//

import SwiftUI

struct CreateEscrowFlowView: View {
    @Environment(\.dismiss) var dismiss
    var viewModel: EscrowViewModel
    var onComplete: (() -> Void)? = nil
    
    @State private var currentStep = 1
    @State private var vendorName = ""
    @State private var vendorEmail = ""
    @State private var serviceType = "Photography"
    @State private var depositAmount = ""
    @State private var serviceDate = Date()
    @State private var useMilestones = false
    @State private var milestones: [MilestoneInput] = [
        MilestoneInput(description: "", amount: "", releaseConditions: "", dueDate: nil)
    ]
    @State private var isLoading = false
    @State private var showValidationError = false
    @State private var showPartyPicker = false
    @State private var selectedSellerId: Int = 0
    @State private var selectedUsers: [User] = []
    
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("authToken") var authToken: String = ""
    
    let serviceTypes = ["Photography", "Videography", "Catering", "Venue", "DJ/Music", "Florist", "Hair & Makeup", "Other"]
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            progressBar
            
            ScrollView {
                VStack(spacing: 24) {
                    if currentStep == 1 {
                        step1VendorInfo
                    } else if currentStep == 2 {
                        step2PaymentDetails
                    } else {
                        step3Review
                    }
                }
                .padding(24)
                .padding(.bottom, 100)
            }
            
            bottomButtons
        }
        .background(Color(red: 0.97, green: 0.93, blue: 0.85).ignoresSafeArea())
        .sheet(isPresented: $showPartyPicker) {
            UserSearchSheetView(
                viewModel: UserSearchViewModel(),
                currentUserId: userId
            ) { user in
                vendorName = user.name
                vendorEmail = user.email
                selectedSellerId = user.id
                selectedUsers = [user]
                showPartyPicker = false
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("STEP \(currentStep)")
                    .font(.custom("DelaGothicOne-Regular", size: 16))
                    .foregroundColor(.black)
                
                Text(stepTitle)
                    .font(.custom("DelaGothicOne-Regular", size: 28))
                    .foregroundColor(Color("ActiveColor"))
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.yellow.opacity(0.8))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: geometry.size.width * CGFloat(currentStep) / 3, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }
    
    private var step1VendorInfo: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                EscrowSectionHeader(title: "VENDOR NAME", isRequired: true)
                
                TextField("e.g., Sarah Chen Photography", text: $vendorName)
                    .textFieldStyle(EscrowTextFieldStyle(hasError: showValidationError && vendorName.isEmpty))
                
                if showValidationError && vendorName.isEmpty {
                    ValidationErrorText(message: "Vendor name is required")
                }
            }
            
            Button(action: { showPartyPicker = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("SELECT EXISTING USER")
                        .font(.custom("DelaGothicOne-Regular", size: 14))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(18)
                .background(Color.yellow.opacity(0.8))
                .cornerRadius(12)
            }
            
            if !selectedUsers.isEmpty, let user = selectedUsers.first {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color("ActiveColor"))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(initials(for: user.name))
                                .font(.custom("DelaGothicOne-Regular", size: 14))
                                .foregroundColor(.black)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.custom("DelaGothicOne-Regular", size: 13))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedUsers = []
                        selectedSellerId = 0
                        vendorName = ""
                        vendorEmail = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(10)
            }
            
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 8)
            
            if selectedUsers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    EscrowSectionHeader(title: "VENDOR EMAIL", isRequired: true)
                    
                    TextField("vendor@email.com", text: $vendorEmail)
                        .textFieldStyle(EscrowTextFieldStyle(hasError: showValidationError && vendorEmail.isEmpty))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    if showValidationError && vendorEmail.isEmpty {
                        ValidationErrorText(message: "Vendor email is required")
                    }
                    
                    Text("We'll send them an invitation to accept the escrow")
                        .font(.custom("IBMPlexMono-Regular", size: 11))
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                EscrowSectionHeader(title: "SERVICE TYPE")
                
                Menu {
                    ForEach(serviceTypes, id: \.self) { type in
                        Button(type) {
                            serviceType = type
                        }
                    }
                } label: {
                    HStack {
                        Text(serviceType)
                            .font(.custom("IBMPlexMono-Regular", size: 15))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var step2PaymentDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                EscrowSectionHeader(title: "DEPOSIT AMOUNT", isRequired: true)
                
                HStack(spacing: 12) {
                    Text("$")
                        .font(.custom("DelaGothicOne-Regular", size: 24))
                        .foregroundColor(.black.opacity(0.5))
                    
                    TextField("0.00", text: $depositAmount)
                        .font(.custom("DelaGothicOne-Regular", size: 24))
                        .foregroundColor(.black)
                        .keyboardType(.decimalPad)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showValidationError && depositAmount.isEmpty ? Color.red : Color.black.opacity(0.1), lineWidth: 1.5)
                )
                
                if showValidationError && depositAmount.isEmpty {
                    ValidationErrorText(message: "Deposit amount is required")
                }
                
                if let amount = Double(depositAmount), amount > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YOUR FEE (3.5%)")
                                .font(.custom("IBMPlexMono-Regular", size: 10))
                                .foregroundColor(.black.opacity(0.5))
                            
                            Text("$\(calculateFee(amount), specifier: "%.2f")")
                                .font(.custom("DelaGothicOne-Regular", size: 18))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("VENDOR PAYS")
                                .font(.custom("IBMPlexMono-Regular", size: 10))
                                .foregroundColor(.black.opacity(0.5))
                            
                            Text("$0.00")
                                .font(.custom("DelaGothicOne-Regular", size: 18))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(16)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                EscrowSectionHeader(title: "SERVICE DATE")
                
                DatePicker("", selection: $serviceDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $useMilestones.animation()) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MILESTONE PAYMENTS")
                            .font(.custom("DelaGothicOne-Regular", size: 15))
                            .foregroundColor(.black)
                        
                        Text("Split payment across deliverables")
                            .font(.custom("IBMPlexMono-Regular", size: 11))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.yellow.opacity(0.8)))
                .padding(18)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(useMilestones ? Color.yellow.opacity(0.8) : Color.black.opacity(0.1), lineWidth: 2)
                )
                
                if useMilestones {
                    VStack(spacing: 12) {
                        ForEach(milestones.indices, id: \.self) { index in
                            MilestoneCard(
                                milestone: $milestones[index],
                                index: index + 1,
                                onRemove: {
                                    if milestones.count > 1 {
                                        milestones.remove(at: index)
                                    }
                                }
                            )
                        }
                        
                        Button(action: {
                            milestones.append(MilestoneInput(description: "", amount: "", releaseConditions: "", dueDate: nil))
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("ADD MILESTONE")
                                    .font(.custom("DaysOne-Regular", size: 12))
                            }
                            .foregroundColor(Color("ActiveColor"))
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("ActiveColor").opacity(0.3), lineWidth: 1.5)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var step3Review: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("REVIEW")
                    .font(.custom("DelaGothicOne-Regular", size: 14))
                    .foregroundColor(.black.opacity(0.5))
                
                Text("ESCROW DETAILS")
                    .font(.custom("DelaGothicOne-Regular", size: 22))
                    .foregroundColor(.black)
            }
            
            VStack(spacing: 16) {
                ReviewRow(label: "VENDOR", value: vendorName)
                if selectedUsers.isEmpty {
                    ReviewRow(label: "EMAIL", value: vendorEmail)
                }
                ReviewRow(label: "SERVICE", value: serviceType)
                ReviewRow(label: "AMOUNT", value: "$\(depositAmount)")
                ReviewRow(label: "DATE", value: formatDate(serviceDate))
                
                if useMilestones && !milestones.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MILESTONES")
                            .font(.custom("DelaGothicOne-Regular", size: 12))
                            .foregroundColor(.black.opacity(0.5))
                            .padding(.top, 8)
                        
                        ForEach(milestones.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(milestones[index].description.isEmpty ? "Milestone \(index + 1)" : milestones[index].description)
                                        .font(.custom("IBMPlexMono-Regular", size: 13))
                                        .foregroundColor(.black)
                                    
                                    if let dueDate = milestones[index].dueDate {
                                        Text(formatDate(dueDate))
                                            .font(.custom("IBMPlexMono-Regular", size: 11))
                                            .foregroundColor(.black.opacity(0.5))
                                    } else {
                                        Text("No due date")
                                            .font(.custom("IBMPlexMono-Regular", size: 11))
                                            .foregroundColor(.black.opacity(0.4))
                                            .italic()
                                    }
                                }
                                
                                Spacer()
                                
                                Text("$\(milestones[index].amount)")
                                    .font(.custom("DelaGothicOne-Regular", size: 16))
                                    .foregroundColor(.black)
                            }
                            .padding(14)
                            .background(Color.yellow.opacity(0.4))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("WHAT HAPPENS NEXT")
                    .font(.custom("DelaGothicOne-Regular", size: 13))
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 10) {
                    BulletPoint(text: "Vendor gets email to accept escrow")
                    BulletPoint(text: "Funds held until service delivered")
                    BulletPoint(text: "You release payment when satisfied")
                    BulletPoint(text: "Instant refund if vendor cancels")
                }
            }
            .padding(18)
            .background(Color.yellow.opacity(0.3))
            .cornerRadius(12)
        }
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            if currentStep < 3 {
                Button(action: nextStep) {
                    Text("CONTINUE")
                        .font(.custom("DaysOne-Regular", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canProceed ? Color.black : Color.black.opacity(0.3))
                        )
                }
                .disabled(!canProceed)
            } else {
                Button(action: submitEscrow) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text(isLoading ? "CREATING..." : "CREATE ESCROW")
                            .font(.custom("DaysOne-Regular", size: 16))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black)
                    )
                }
                .disabled(isLoading)
            }
            
            if currentStep > 1 {
                Button(action: { currentStep -= 1 }) {
                    Text("BACK")
                        .font(.custom("IBMPlexMono-Regular", size: 14))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .padding(24)
        .background(Color(red: 0.97, green: 0.93, blue: 0.85))
    }
    
    private var stepTitle: String {
        switch currentStep {
        case 1: return "VENDOR INFO"
        case 2: return "PAYMENT"
        case 3: return "REVIEW"
        default: return ""
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            if !selectedUsers.isEmpty {
                return !vendorName.isEmpty
            } else {
                return !vendorName.isEmpty && !vendorEmail.isEmpty && vendorEmail.contains("@")
            }
        case 2:
            guard let amount = Double(depositAmount), amount > 0 else { return false }
            if useMilestones {
                let validMilestones = milestones.filter {
                    !$0.amount.isEmpty && Double($0.amount) != nil && Double($0.amount)! > 0
                }
                let milestoneTotal = validMilestones.compactMap { Double($0.amount) }.reduce(0, +)
                return !validMilestones.isEmpty && milestoneTotal == amount
            }
            return true
        default:
            return true
        }
    }
    
    private func nextStep() {
        if canProceed {
            showValidationError = false
            withAnimation {
                currentStep += 1
            }
        } else {
            showValidationError = true
        }
    }
    
    private func submitEscrow() {
        print("$$$ Auth token:", authToken.isEmpty ? "EMPTY" : "Present")
        print("$$$ submitEscrow called")
        isLoading = true
        
        guard let amount = Double(depositAmount) else {
            print("$$$ Invalid deposit amount")
            isLoading = false
            return
        }
        
        let totalCents = Int((amount * 100).rounded())
        var milestonePayload: [[String: Any]] = []
        
        if useMilestones {
            milestonePayload = milestones.compactMap { milestone in
                guard let milestoneAmount = Double(milestone.amount) else { return nil }
                var payload: [String: Any] = [
                    "description": milestone.description,
                    "amountCents": Int((milestoneAmount * 100).rounded()),
                    "releaseConditions": milestone.releaseConditions
                ]
                
                if let dueDate = milestone.dueDate {
                    payload["dueDate"] = ISO8601DateFormatter().string(from: dueDate)
                }
                
                return payload
            }
        }
        
        let payload: [String: Any] = [
            "title": "\(serviceType) - \(vendorName)",
            "vendorEmail": vendorEmail,
            "vendorName": vendorName,
            "sellerId": selectedSellerId != 0 ? selectedSellerId : 0,
            "amountCents": totalCents,
            "serviceType": serviceType,
            "serviceDate": ISO8601DateFormatter().string(from: serviceDate),
            "status": "PENDING",
            "milestones": milestonePayload
        ]
        
        print("$$$ Payload:", payload)
        
        guard let url = URL(string: "https://go-hard-backend-production.up.railway.app/escrow/create"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            print("❌ Failed to create URL or body")
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        print("$$$ Making request to:", url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("$$$ Network error:", error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("$$$ Status code:", httpResponse.statusCode)
                }
                
                guard let data = data else {
                    print("$$$ No data received")
                    return
                }
                
                print("$$$ Response data:", String(data: data, encoding: .utf8) ?? "Unable to decode")
                
                do {
                    let dto = try JSONDecoder().decode(EscrowDTO.self, from: data)
                    print("$$$ Successfully decoded EscrowDTO")
                    let project = dto.toProject()
                    viewModel.addEscrow(project)
                    
                    if let onComplete = onComplete {
                        onComplete()
                    } else {
                        dismiss()
                    }
                } catch {
                    print("$$$ Decode error:", error)
                }
            }
        }.resume()
    }
    
    private func calculateFee(_ amount: Double) -> Double {
        return max(50, amount * 0.035)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func validationBorder(isEmpty: Bool) -> Color {
        if showValidationError && isEmpty {
            return Color.red
        }
        return Color.black.opacity(0.1)
    }
    
    private func initials(for name: String) -> String {
        let components = name.split(separator: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }
}

struct MilestoneInput: Identifiable {
    let id = UUID()
    var description: String
    var amount: String
    var releaseConditions: String
    var dueDate: Date?
}

struct MilestoneCard: View {
    @Binding var milestone: MilestoneInput
    let index: Int
    let onRemove: () -> Void
    @State private var showDatePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MILESTONE \(index)")
                    .font(.custom("DaysOne-Regular", size: 11))
                    .foregroundColor(.black.opacity(0.6))
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            
            TextField("Title (e.g., Initial consultation)", text: $milestone.description)
                .font(.custom("IBMPlexMono-Regular", size: 13))
                .padding(12)
                .background(Color(red: 0.97, green: 0.93, blue: 0.85))
                .cornerRadius(8)
            
            TextField("Release conditions (e.g., After venue confirms booking)", text: $milestone.releaseConditions, axis: .vertical)
                .font(.custom("IBMPlexMono-Regular", size: 12))
                .padding(12)
                .background(Color(red: 0.97, green: 0.93, blue: 0.85))
                .cornerRadius(8)
                .frame(minHeight: 60, alignment: .topLeading)
            
            HStack(spacing: 12) {
                HStack {
                    Text("$")
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .foregroundColor(.black.opacity(0.5))
                    
                    TextField("0.00", text: $milestone.amount)
                        .font(.custom("DelaGothicOne-Regular", size: 16))
                        .keyboardType(.decimalPad)
                }
                .padding(12)
                .background(Color(red: 0.97, green: 0.93, blue: 0.85))
                .cornerRadius(8)
                
                if let date = milestone.dueDate {
                    DatePicker("", selection: Binding(
                        get: { date },
                        set: { milestone.dueDate = $0 }
                    ), displayedComponents: .date)
                    .labelsHidden()
                    .padding(8)
                    .background(Color(red: 0.97, green: 0.93, blue: 0.85))
                    .cornerRadius(8)
                    
                    Button(action: { milestone.dueDate = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red.opacity(0.6))
                    }
                } else {
                    Button(action: { milestone.dueDate = Date() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 12))
                            Text("Add date")
                                .font(.custom("IBMPlexMono-Regular", size: 11))
                        }
                        .foregroundColor(.black.opacity(0.6))
                        .padding(10)
                        .background(Color(red: 0.97, green: 0.93, blue: 0.85))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("DelaGothicOne-Regular", size: 11))
                .foregroundColor(.black.opacity(0.5))
            
            Spacer()
            
            Text(value)
                .font(.custom("IBMPlexMono-Regular", size: 14))
                .foregroundColor(.black)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.black)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.custom("IBMPlexMono-Regular", size: 13))
                .foregroundColor(.black.opacity(0.8))
        }
    }
}

struct ValidationMessage: View {
    let text: String
    
    var body: some View {
        ValidationErrorText(message: text)
    }
}

#Preview {
    CreateEscrowFlowView(viewModel: EscrowViewModel())
}

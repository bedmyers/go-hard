//
//  AddVendorViewModel.swift
//  Goldy
//
//  Created by Blair Myers on 11/25/25.
//

import SwiftUI

// MARK: - Step Enum

enum AddVendorStep: Int, CaseIterable {
    case vendorInfo = 0
    case paymentSetup = 1
    case terms = 2
    case review = 3
    
    var title: String {
        switch self {
        case .vendorInfo: return "Vendor Info"
        case .paymentSetup: return "Payment Setup"
        case .terms: return "Terms & Conditions"
        case .review: return "Review & Send"
        }
    }
    
    var shortTitle: String {
        switch self {
        case .vendorInfo: return "Info"
        case .paymentSetup: return "Payment"
        case .terms: return "Terms"
        case .review: return "Review"
        }
    }
    
    var subtitle: String {
        switch self {
        case .vendorInfo: return "Who are you working with?"
        case .paymentSetup: return "Set up your payment milestones"
        case .terms: return "Review the agreement terms"
        case .review: return "Confirm and send to vendor"
        }
    }
}

// MARK: - Data Models

struct MilestoneInput: Identifiable {
    let id = UUID()
    var amount: String = ""
    var description: String = ""
    var dueDate: Date? = nil
    var releaseCondition: String = ""
}

struct TermsSection: Identifiable {
    let id = UUID()
    var title: String
    var content: String
    var isEnabled: Bool = true
}

enum MilestoneTemplate {
    case fiftyFifty
    case thirtyThirtyForty
    case depositFinal
}

// MARK: - ViewModel

@MainActor
class AddVendorViewModel: ObservableObject {
    // MARK: - Navigation
    @Published var currentStep: AddVendorStep = .vendorInfo
    @Published var isSubmitting = false
    @Published var didComplete = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    // MARK: - Step 1: Vendor Info
    @Published var vendorName: String = ""
    @Published var vendorEmail: String = ""
    @Published var vendorRole: String = ""
    @Published var vendorDescription: String = ""
    
    // MARK: - Step 2: Payment Setup
    @Published var totalAmount: String = ""
    @Published var milestones: [MilestoneInput] = []
    
    // MARK: - Step 3: Terms
    @Published var termsSections: [TermsSection] = []
    
    private let api = APIService.shared
    
    // MARK: - Validation
    
    var canProceed: Bool {
        switch currentStep {
        case .vendorInfo:
            return isValidVendorInfo
        case .paymentSetup:
            return isValidPaymentSetup
        case .terms:
            return true
        case .review:
            return isValidVendorInfo && isValidPaymentSetup
        }
    }
    
    private var isValidVendorInfo: Bool {
        !vendorName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(vendorEmail) &&
        !vendorRole.isEmpty
    }
    
    private var isValidPaymentSetup: Bool {
        guard let total = Int(totalAmount), total > 0 else { return false }
        guard !milestones.isEmpty else { return false }
        
        let milestoneTotal = milestones.reduce(0) { $0 + (Int($1.amount) ?? 0) }
        return milestoneTotal == total
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Navigation
    
    func goNext() {
        guard canProceed else { return }
        
        if let nextStep = AddVendorStep(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = nextStep
            }
        }
    }
    
    func goBack() {
        if let prevStep = AddVendorStep(rawValue: currentStep.rawValue - 1) {
            withAnimation {
                currentStep = prevStep
            }
        }
    }
    
    // MARK: - Milestones
    
    func addMilestone() {
        milestones.append(MilestoneInput())
    }
    
    func removeMilestone(at index: Int) {
        guard milestones.indices.contains(index) else { return }
        milestones.remove(at: index)
    }
    
    func applyTemplate(_ template: MilestoneTemplate) {
        guard let total = Int(totalAmount), total > 0 else {
            errorMessage = "Enter a total amount first"
            showError = true
            return
        }
        
        milestones.removeAll()
        
        switch template {
        case .fiftyFifty:
            let half = total / 2
            milestones = [
                MilestoneInput(
                    amount: "\(half)",
                    description: "Deposit",
                    dueDate: Date(),
                    releaseCondition: "Upon booking confirmation"
                ),
                MilestoneInput(
                    amount: "\(total - half)",
                    description: "Final Payment",
                    dueDate: nil,
                    releaseCondition: "After service completion"
                )
            ]
            
        case .thirtyThirtyForty:
            let first = Int(Double(total) * 0.3)
            let second = Int(Double(total) * 0.3)
            let third = total - first - second
            milestones = [
                MilestoneInput(
                    amount: "\(first)",
                    description: "Deposit",
                    dueDate: Date(),
                    releaseCondition: "Upon booking confirmation"
                ),
                MilestoneInput(
                    amount: "\(second)",
                    description: "Progress Payment",
                    dueDate: nil,
                    releaseCondition: "At planning milestone"
                ),
                MilestoneInput(
                    amount: "\(third)",
                    description: "Final Payment",
                    dueDate: nil,
                    releaseCondition: "After service completion"
                )
            ]
            
        case .depositFinal:
            let deposit = Int(Double(total) * 0.25)
            let final = total - deposit
            milestones = [
                MilestoneInput(
                    amount: "\(deposit)",
                    description: "Booking Deposit",
                    dueDate: Date(),
                    releaseCondition: "Upon booking confirmation"
                ),
                MilestoneInput(
                    amount: "\(final)",
                    description: "Balance Due",
                    dueDate: nil,
                    releaseCondition: "7 days before event"
                )
            ]
        }
    }
    
    // MARK: - Terms Generation
    
    func generateTerms() {
        guard termsSections.isEmpty else { return }
        
        let total = Int(totalAmount) ?? 0
        let formattedTotal = NumberFormatter.localizedString(from: NSNumber(value: total), number: .currency)
        
        termsSections = [
            TermsSection(
                title: "Service Description",
                content: generateServiceDescription()
            ),
            TermsSection(
                title: "Payment Terms",
                content: generatePaymentTerms(formattedTotal: formattedTotal)
            ),
            TermsSection(
                title: "Cancellation Policy",
                content: generateCancellationPolicy()
            ),
            TermsSection(
                title: "Deliverables & Timeline",
                content: generateDeliverablesTerms()
            ),
            TermsSection(
                title: "Liability & Disputes",
                content: generateLiabilityTerms()
            )
        ]
    }
    
    private func generateServiceDescription() -> String {
        let roleDescription: String
        switch vendorRole.lowercased() {
        case "venue":
            roleDescription = "venue rental and associated services including access to the space, basic amenities, and on-site coordination"
        case "catering":
            roleDescription = "catering services including food preparation, service staff, and related equipment as agreed upon"
        case "photography":
            roleDescription = "professional photography services including coverage of the event, edited digital images, and usage rights as specified"
        case "videography":
            roleDescription = "professional videography services including event coverage, editing, and final video deliverables as specified"
        case "florals":
            roleDescription = "floral design and arrangements including consultation, design, delivery, and setup as agreed upon"
        case "music/dj":
            roleDescription = "music and entertainment services including equipment, performance/DJ services, and coordination with venue"
        case "wedding planner":
            roleDescription = "event planning and coordination services including vendor management, timeline creation, and day-of coordination"
        case "hair & makeup":
            roleDescription = "professional hair and makeup services including trials (if applicable) and day-of styling"
        default:
            roleDescription = "\(vendorRole.lowercased()) services as discussed and agreed upon between both parties"
        }
        
        return "\(vendorName) agrees to provide \(roleDescription). Any additional services beyond this scope must be agreed upon in writing and may be subject to additional fees."
    }
    
    private func generatePaymentTerms(formattedTotal: String) -> String {
        var terms = "Total contract value: \(formattedTotal)\n\n"
        terms += "Payment will be made through Go Hard's secure escrow system according to the following schedule:\n\n"
        
        for (index, milestone) in milestones.enumerated() {
            let amount = Int(milestone.amount) ?? 0
            let formatted = NumberFormatter.localizedString(from: NSNumber(value: amount), number: .currency)
            terms += "• \(milestone.description.isEmpty ? "Payment \(index + 1)" : milestone.description): \(formatted)"
            
            if !milestone.releaseCondition.isEmpty {
                terms += " — \(milestone.releaseCondition)"
            }
            terms += "\n"
        }
        
        terms += "\nFunds are held securely in escrow until release conditions are met and approved by the customer."
        
        return terms
    }
    
    private func generateCancellationPolicy() -> String {
        return """
        Cancellation by Customer:
        • More than 90 days before event: Full refund minus 10% administrative fee
        • 60-90 days before event: 50% refund
        • 30-60 days before event: 25% refund
        • Less than 30 days before event: No refund unless vendor can rebook the date
        
        Cancellation by Vendor:
        • Vendor must provide as much notice as possible
        • Full refund of any funds held in escrow
        • Vendor agrees to assist in finding replacement services if possible
        
        Force Majeure:
        • In case of circumstances beyond either party's control (natural disasters, government restrictions, etc.), both parties agree to negotiate in good faith for rescheduling or refund.
        """
    }
    
    private func generateDeliverablesTerms() -> String {
        switch vendorRole.lowercased() {
        case "photography":
            return """
            • Photographer will deliver a minimum of [X] edited digital images
            • Initial preview gallery within 2 weeks of event
            • Full edited gallery within 6-8 weeks of event
            • Images delivered via online gallery with download access
            • Print rights included for personal use
            """
        case "videography":
            return """
            • Videographer will deliver edited video as agreed (highlight reel, full ceremony, etc.)
            • Initial preview/trailer within 2 weeks of event
            • Final edited video within 8-12 weeks of event
            • Video delivered via digital download or streaming link
            """
        case "venue":
            return """
            • Access to venue space for agreed-upon hours
            • Setup time begins at [time] on day of event
            • Event concludes by [time]
            • Cleanup/teardown completed by [time]
            • Any overtime subject to additional hourly fees
            """
        case "catering":
            return """
            • Final guest count due [X] days before event
            • Menu tasting included (if applicable)
            • Service staff for duration of meal service
            • All food prep, serving equipment, and cleanup included
            • Dietary accommodations as discussed
            """
        default:
            return """
            • Services to be provided as discussed and agreed upon
            • Timeline and specific deliverables as confirmed in writing
            • Any changes to scope must be agreed upon by both parties
            • Final details to be confirmed [X] days before event
            """
        }
    }
    
    private func generateLiabilityTerms() -> String {
        return """
        Limitation of Liability:
        • Vendor's liability is limited to the total contract value
        • Neither party liable for indirect, incidental, or consequential damages
        • Vendor maintains appropriate insurance for their services
        
        Dispute Resolution:
        • Both parties agree to attempt good-faith resolution of any disputes
        • Unresolved disputes may be submitted to Go Hard's mediation process
        • Either party may seek legal remedies if mediation is unsuccessful
        
        This agreement is governed by the laws of the state where services are rendered.
        """
    }
    
    // MARK: - Submission
    
    func submitVendor(projectId: Int) async {
        guard isValidVendorInfo && isValidPaymentSetup else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let vendorBody: [String: Any] = [
                "vendorEmail": vendorEmail.trimmingCharacters(in: .whitespaces).lowercased(),
                "role": vendorRole,
                "description": vendorDescription.isEmpty ? NSNull() : vendorDescription,
                "amountCents": (Int(totalAmount) ?? 0) * 100,
                "dueDate": milestones.last?.dueDate.map { ISO8601DateFormatter().string(from: $0) } ?? NSNull()
            ]
            
            let projectVendor: ProjectVendorResponse = try await api.addVendorToProject(
                projectId: projectId,
                body: vendorBody
            )
            
            print("✅ Added vendor to project: \(projectVendor.id)")
            
            let milestonesData: [[String: Any]] = milestones.map { milestone in
                var data: [String: Any] = [
                    "amountCents": (Int(milestone.amount) ?? 0) * 100,
                    "description": milestone.description.isEmpty ? NSNull() : milestone.description,
                    "releaseConditions": milestone.releaseCondition.isEmpty ? NSNull() : milestone.releaseCondition
                ]
                
                if let dueDate = milestone.dueDate {
                    data["dueDate"] = ISO8601DateFormatter().string(from: dueDate)
                }
                
                return data
            }
            
            let escrowBody: [String: Any] = [
                "milestones": milestonesData
            ]
            
            do {
                let escrow: EscrowResponse = try await api.createEscrow(
                    projectVendorId: projectVendor.id,
                    body: escrowBody
                )
                print("✅ Created escrow: \(escrow.id)")
            } catch {
                print("⚠️ Escrow not created yet (vendor may need to complete Stripe setup): \(error.localizedDescription)")
            }
            
            didComplete = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error adding vendor: \(error)")
        }
        
        isSubmitting = false
    }
}

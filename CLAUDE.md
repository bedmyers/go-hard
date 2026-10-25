# Go Hard iOS

Wedding escrow app - SwiftUI frontend.

## Stack
- Swift 5 / SwiftUI
- iOS 17+
- No external dependencies (vanilla URLSession for networking)

## File Structure
- `Models/` - Data models (User, Project, Escrow, RFP, Bid, etc.)
- `Services/APIService.swift` - All API calls
- `Views/` - SwiftUI views organized by feature

## Design System
Colors (use Color(hex: "...")):
- Background: #F5F1E8 (warm beige)
- Gold/Primary: #FFD700
- Green/Success: #22C55E
- Orange: #FF6B35
- Purple: #8B5CF6
- Blue: #3B82F6
- Pinterest Red: #E60023

Typography:
- Titles: DelaGothicOne-Regular
- Body: System font

Style:
- Bold, aggressive design - NOT minimal
- White cards with subtle shadows
- Rounded corners (12-16pt)

## Key Patterns
- Auth token stored in UserDefaults
- APIService.shared singleton for all network calls
- Amounts come from API in cents, format with `amountFormatted` computed properties
- Use `.task { }` for async data loading
- Pull-to-refresh with `.refreshable { }`

## User Flows
- Customer: Create projects, add vendors, manage escrows, post RFPs, review bids
- Vendor: Browse RFPs, submit bids, track bid status, manage payouts via Stripe

## Backend
Base URL: https://go-hard-backend-production.up.railway.app

## Git Workflow
- `main` is protected: all changes go through a pull request (no direct pushes)
- Branch off `main` for each change: `feat/...`, `fix/...`, `chore/...`
- Open a PR into `main`, then merge; delete the branch after merging
- Tag each TestFlight/App Store build, e.g. `v0.1.0-5` (version-build)
- If a change depends on a backend change, ship the backend first and keep it compatible with the app version already in users' hands
- No Claude/AI attribution lines in commits or PRs

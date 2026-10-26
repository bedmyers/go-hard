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
The app is locked to light mode (`UIUserInterfaceStyle = Light`).

Colors (use Color(hex: "...")):
- Background: `Color("Background")` asset (#F1E8D9, warm beige) on every screen
- Gold/Primary: #FFD700
- Green/Success: #22C55E
- Orange: #FF6B35
- Purple: #8B5CF6
- Blue: #3B82F6
- Pinterest Red: #E60023

Typography:
- Titles/headings: DelaGothicOne-Regular (navigation titles too, via `AppAppearance`)
- Body: Spectral (`Spectral-Regular`, `-Medium`, `-Bold`); section labels are Spectral-Bold 12 in caps

Components:
- Cards: `.cardStyle()` (white, 12pt corners, standard shadow) or `.cardStyle(cornerRadius: 16)` for large cards. Don't hand-roll card backgrounds/shadows.
- Main buttons: full width, DelaGothicOne 14, `.padding(.vertical, 16)`, 12pt corners; black or gold fill. Secondary: white with a light 1pt border.
- Buttons inside cards: Spectral-Bold 12, `.padding(.vertical, 12)`, 8pt corners.
- Text fields: white, 10pt corners.
- Toolbar buttons: plain icon/label only; iOS draws the button background.

Style:
- Bold, aggressive design - NOT minimal

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

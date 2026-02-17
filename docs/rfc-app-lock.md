# RFC: Transition to Local-First Security Model (App Lock)

## Problem
The current implementation relies on Firebase Authentication and Google Sign-In for app entry. This introduces unnecessary friction for users who prefer a local-only financial tracking experience without the need for cloud accounts or internet connectivity during onboarding.

## Proposal
Replace the Firebase-based authentication system with a "Local-First" model:
1. **Landing Page**: Introduce a premium onboarding screen for new users to "Get Started" without sign-up.
2. **Local Identity**: Use the existing local SQLite `users` table to maintain a guest/local profile.
3. **App Lock**: Implement an optional security layer (PIN Code and Biometrics/Fingerprint) that guards app access.
4. **Removal of Firebase**: Decommission Firebase Core, Firebase Auth, and Google Sign-In dependencies.

## Implementation Details
1. **Core Navigation**: Update `main.dart` to use a `LandingPage` for uninitialized users and a `LockScreen` for returning users with security enabled.
2. **Security Provider**: Create/Update `AuthProvider` to handle:
   - PIN setup and verification.
   - Biometric authentication via `local_auth`.
   - Onboarding state management.
3. **UI/UX**:
   - Create `LandingPage` with high-aesthetic visuals and "Get Started" CTA.
   - Create `LockScreen` with a numeric keypad for PIN entry.
   - Update `SettingsScreen` to include "Security" options.

## Alternatives
- **Hybrid Auth**: Keep Firebase as an optional "Sync" feature. 
  - *Decision*: Deferred to maintain simplicity and focus on the current user request for removal.

## Trade-offs
- **Pros**: Reduced app size, faster startup, improved privacy, works offline.
- **Cons**: No cloud backup (for now), security is limited to the physical device.

## Migration Plan
- Users currently authenticated via Firebase will be treated as local users. 
- Shared preferences will be used to track if onboarding is completed.
- Firebase initialization will be removed from `main.dart`.

## Open Questions
- Should we provide an export/import feature for data backup since cloud sync is removed? (To be addressed in a future phase).

## Decision Outcome
Approved - Implementation follows.

Date: 2026-02-17

# Technical Specification: App Lock & Local Auth System

## System Overview
The Expenze Mobile security system is transitioning from a cloud-based Firebase identity provider to a decentralized, local-only model. Security is enforced at the application entry point via a PIN-based gatekeeper with optional biometric (Fingerprint/FaceID) support.

## Architecture Diagram (ASCII)
```
[ App Start ]
      |
[ AuthProvider: Check Onboarding ] -- No --> [ LandingPage ]
      |                                           |
     Yes                                     [ Finish Onboarding ]
      |                                           |
[ AuthProvider: Check App Lock ] -- No --> [ Dashboard ]
      |
     Yes
      |
[ LockScreen ] <--- [ Biometric Prompt ]
      |
[ Verify PIN/Biometric ] -- Success --> [ Dashboard ]
```

## Component Breakdown
1. **AuthProvider**: State management for user identity, onboarding status, and security preferences.
2. **LandingPage**: UI component for first-time user interaction.
3. **LockScreen**: Numeric input screen for PIN verification.
4. **LocalAuthService**: Wrapper for the `local_auth` package to handle biometrics.
5. **DatabaseHelper**: Manages the local `users` table for profile data.

## Data Flow
- **Onboarding**: `SharedPreferences` stores `is_onboarded: true`.
- **Security Prefs**: `SharedPreferences` stores `is_lock_enabled: true` and `use_biometrics: true`.
- **PIN Storage**: Stored securely in `SharedPreferences` (hashed) or via `flutter_secure_storage` (if enabled in future).

## API Contracts (Internal)
- `AuthProvider.verifyPin(String pin)` -> `bool`
- `AuthProvider.authenticateBiometric()` -> `bool`
- `AuthProvider.setOnboardingComplete()` -> `void`

## Validation Rules
- **PIN**: Must be exactly 4 or 6 numeric digits.
- **Attempts**: Lock input for 30 seconds after 5 failed attempts (Logic implemented in AuthProvider).

## Error Handling
- **No Biometrics**: Fallback gracefully to PIN entry.
- **Canceled Biometrics**: Stay on PIN screen.
- **Locked Hardware**: Display error message to user.

## Security Model
- **STRIDE Analysis**: 
  - *Spoofing*: Mitigated by PIN/Biometric local verification.
  - *Tampering*: SQLite DB is encrypted (future) or private to the app sandbox.
  - *Information Disclosure*: Data resides only in protected app storage.

## Performance Analysis
- Faster startup time (-500ms to -1.5s) by removing Firebase initialization and network overhead.
- Negligible impact on memory/CPU.

## Deployment & Rollback
- **Deployment**: Replace `FirebaseAuth` logic in `AuthProvider`, update `main.dart`.
- **Rollback**: Revert to `git commit` prior to this spec implementation.

Date: 2026-02-17

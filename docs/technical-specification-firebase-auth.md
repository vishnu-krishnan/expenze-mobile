# Technical Specification - Firebase Authentication Integration

## System Overview
A hybrid authentication architecture combining **Firebase Authentication** for identity verification and **SQLite** for local financial data storage. This ensures a secure, managed identity while preserving the user's privacy and offline capabilities for transaction tracking.

## Architecture Diagram
```text
[ Presentation Layer ] (Screens, Providers)
         |
         v
[ AuthProvider (Logic Bridge) ]
         |
         +----------------------------------+
         |                                  |
         v                                  v
[ FirebaseAuth SDK ]               [ DatabaseHelper (SQLite) ]
(Cloud Identity)                   (Local User Profile & Financials)
```

## Component Breakdown
- **Firebase Core/Auth SDK**: Manages JWT tokens, session persistence, and Google/Email handshakes.
- **AuthProvider**: Acts as the central state manager. Listens to `authStateChanges()` and synchronizes the global UI state.
- **GoogleSignIn**: Handles native OAuth2 flows and provides `idToken` for Firebase credential exchange.
- **DatabaseHelper**: Maintains a local mirror of the user profile in the `users` table to link financial records (expenses, categories).

## Data Flow (Google Sign-In)
1. User triggers Google Sign-In.
2. `google_sign_in` SDK retrieves `GoogleSignInAccount`.
3. Account `idToken` is extracted.
4. `FirebaseAuth` signs in using the token.
5. Firebase returns a `User` object.
6. `AuthProvider` calls `_syncUserWithLocalDB`.
7. `DatabaseHelper.upsertUser` records the Firebase email/UID in local SQLite.

## API Contracts
- **Firebase Auth REST/SDK**: Standard Google Identity Platform endpoints.
- **Google Identity API**: Used for native platform authentication on Android.

## Validation Rules
- **Email**: Must follow standard RFC 5322 format (validated by Firebase).
- **Password**: Minimum 6 characters (enforced by Firebase & UI).
- **Username**: Must be unique within the local SQLite database.

## Error Handling
The system maps `FirebaseAuthException` codes to user-friendly messages:
- `user-not-found` -> "No account found."
- `wrong-password` -> "Incorrect password."
- `email-already-in-use` -> "Email already registered."

## Schema Changes
- No new changes (v4 migration already introduced `full_name`, `email`, and `password` columns).

## Security Model
- **Credential Handling**: No passwords or plain-text credentials are stored locally.
- **Session Tokens**: Handled by Firebase SDK with secure internal persistence.
- **Data Isolation**: Financial data remains local-only, linked only by a local user ID generated during the SQLite sync.

## Deployment Plan
1. Registry of the app in Firebase Console.
2. Integration of `google-services.json`.
3. Project-level and App-level Gradle updates.
4. SDK initialization in `main.dart`.

## Rollback Plan
1. Revert `AuthProvider` logic to use legacy `dbHelper.getUser()` methods.
2. Remove Firebase initialization from `main.dart`.
3. Revert `pubspec.yaml` dependencies.

Date: 2026-02-16

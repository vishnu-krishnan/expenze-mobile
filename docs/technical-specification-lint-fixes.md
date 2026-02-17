# Technical Specification - Lint & Method Fixes

## System Overview
This task addresses technical debt and build blockers identified during the transition to a local-first architecture. 

## Component Breakdown

### 1. AuthProvider (lib/presentation/providers/auth_provider.dart)
- **Problem**: Missing `login`, `register`, `resetPassword`, and `loginWithGoogle` methods.
- **Solution**: Implement these methods to satisfy screen dependencies.
    - `login`: Validates against local PIN/Passcode if available.
    - `register`: Wraps `_dbHelper.upsertUser`.
    - `resetPassword`: Stubbed for local-only flow.
    - `loginWithGoogle`: Marked as deprecated/legacy stub.

### 2. Logging Infrastructure (lib/core/utils/logger.dart)
- **Problem**: Usage of raw `print` statements.
- **Solution**: 
    - Initialize a global `Logger` instance using the `logger` package.
    - Replace `print` in `CategoryProvider` and `ExpenseProvider` with `logger.e` or `logger.d`.

### 3. Context Guarding (Multiple Screens)
- **Problem**: `BuildContext` used after `await` without `mounted` checks.
- **Solution**:
    - Audit `NotesScreen`, `LoginScreen`, `RegisterScreen`, and `ResetPasswordScreen`.
    - Add `if (!mounted) return;` (for State) or `if (context.mounted)` (for BuildContext).

## Data Flow
- No significant changes to data flow. 

## Security Model
- Ensuring `print` is removed prevents potential exposure of data in standard logs (though minimally risky in Flutter, it's best practice).
- Proper guarding of `BuildContext` prevents state leakage or crashes.

## Testing Plan
- **Manual Test**: Verify app builds and runs without "method not found" errors.
- **Manual Test**: Trigger async operations and navigate away to verify no "context unmounted" crashes.
- **Log Verification**: Check terminal for structured logs instead of raw print output.

## Rollback Plan
- Revert changes to `AuthProvider` and screens via Git.

Date: 2026-02-17

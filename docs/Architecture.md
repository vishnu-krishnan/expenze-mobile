# System Architecture - Expenze Mobile

## Tech Stack
- **Framework**: Flutter (3.x)
- **Language**: Dart
- **State Management**: Provider
- **Identity**: Firebase Authentication
- **Local Database**: SQLite (`sqflite`) (schema v12 includes `payment_mode` for expenses)
- **Storage**: `shared_preferences`
- **Networking**: `dio`
- **Icons**: `lucide_icons`
- **Charts**: `fl_chart` (Pie/Line charts for analytics)

## Architecture Layers (Clean Architecture)

### 1. Presentation Layer
- **Screens**: Located in `lib/presentation/screens`.
- **Widgets**: Reusable UI components in `lib/presentation/widgets`.
- **Providers**: App state Controllers in `lib/presentation/providers` (Auth, Expense, Category, Theme, Note, RegularPayment).

### 2. Domain Layer (Models)
- **Models**: Data structures in `lib/data/models` (User, Expense, Category, Note, RegularPayment).
- **Entities**: Business logic rules (currently integrated with models for simplicity).

### 3. Data Layer
- **Repositories**: Data abstraction in `lib/data/repositories`.
- **Services**: External/System interface services (API, Database, SMS) in `lib/data/services`.

## Single Source of Truth
- The local SQLite database (`DatabaseHelper`) is the authoritative source for all financial data.
- UI state is synchronized via `notifyListeners()` in Providers.

## Security Standards
- Secure token storage with Firebase Authentication identity provider.
- Local-only data processing for financial and sensitive info (SMS, Transactions).
- Managed session persistence with automatic token refreshing.
- Runtime permission management.

## Design Architecture
### Unified Background System
- **Single Source of Truth**: Background decorations are defined globally in `AppTheme`.
- **Inherited Decoration**: `MainNavigationWrapper` provides the primary background container for the persistent shell.
- **Transparent Scaffolds**: Individual screens within the shell use `Colors.transparent` to ensure seamless visual integration.
- **Standalone Resilience**: Screens outside the shell (Auth, Onboarding) implement their own `Container` using the same `AppTheme` definitions.

Date: 2026-02-18

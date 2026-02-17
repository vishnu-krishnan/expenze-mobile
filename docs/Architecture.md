# System Architecture - Expenze Mobile

## Tech Stack
- **Framework**: Flutter (3.x)
- **Language**: Dart
- **State Management**: Provider
- **Identity**: Firebase Authentication
- **Local Database**: SQLite (`sqflite`)
- **Storage**: `shared_preferences`
- **Networking**: `dio`
- **Icons**: `lucide_icons`
- **Charts**: `fl_chart`

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

Date: 2026-02-16

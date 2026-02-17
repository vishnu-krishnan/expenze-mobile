# Expenze - Technical Specification: UI Cleanliness Refinement

## System Overview
This refinement targets the `presentation` layer of the Expenze mobile application, specifically the `AppBar` and `SliverAppBar` configurations across all screens.

## Component Breakdown
### Navigation System
- **Modification**: Disabled automated and manual back button rendering. Standardized global heading alignment to the left.
- **Affected Widgets**: `Scaffold`, `AppBar`, `SliverAppBar`, `CustomScrollView`, `FlexibleSpaceBar`.
- **Implementation**:
  - `automaticallyImplyLeading: false`
  - Removal of `leading` icons.
  - Set `centerTitle: false` in all `AppBar` and `SliverAppBar` instances.
  - Standardized `titleSpacing` to ensure consistent left-padding across screens (e.g., 26px for standard AppBars).

### Recurring Payments Screen
- **Modification**: Refactored the header to unify the heading.
- **Affected Files**: `lib/presentation/screens/regular/regular_payments_screen.dart`.
- **Implementation**: Removed "Auto-pay Bills" text and changed the primary heading to "Recurring Payments".

### Settings Configuration
- **Modification**: Removal of the `Reset Application` functionality.
- **Affected Files**: `lib/presentation/screens/settings/settings_screen.dart`.
- **Logic**: Removed the `TextButton` trigger and its associated `_showResetPrompt` dialog logic.

## Data Flow
No changes to data flow. The navigation stack remains intact; only the visual triggers (back buttons) for popping the stack are removed. Navigation is expected to be handled via bottom navigation or gesture-based back actions (if supported by OS).

## Security Model
- Increased security by removing the "Reset Application" button, which could be used to clear local security settings (PIN/Biometrics) without authorization.

## Performance Analysis
- Negligible improvement due to fewer widgets being rendered in the `AppBar` tree.

## Technical Impact
- **Maintenance**: Simplifies `AppBar` definitions across the codebase.
- **UX**: Heavy reliance on OS-level gestures for "back" navigation.

## Deployment Plan
- Part of UI Refinement Phase.
- Class: Minor Change.

## Rollback Plan
- Restore `automaticallyImplyLeading: true` or revert the stateful leading icon implementations.
- Re-add the `_showResetPrompt` method and its button in `SettingsScreen`.

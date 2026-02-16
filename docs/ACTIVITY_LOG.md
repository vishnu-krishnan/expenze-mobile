# Activity Log
================================================================================

## [2026-02-12] Flutter Mobile Development Migration Planning

**Change Type:** Major

**Decision Made:**
Planned comprehensive migration from React Native (Expo) to Flutter for mobile 
application development, with focus on physical device testing without emulators.

**Context:**
- Current mobile app uses React Native with Expo
- User wants to continue with Flutter for better performance and native capabilities
- Critical constraint: Limited storage (53GB available, 77% disk usage)
- Critical issue: ADB not detecting Android device on Linux (works on Windows)
- No emulator requirement - physical device testing only

**System Analysis:**
- CPU: Intel Core i5-10210U (4 cores, 8 threads) - Adequate
- RAM: 15GB total, ~5GB available - Adequate
- Storage: 233GB total, 53GB free (77% used) - **CRITICAL CONCERN**
- Java: OpenJDK 21.0.10 - Installed ✅
- ADB: Version 34.0.4 - Installed but misconfigured ❌
- Flutter: Not installed - Required

**Root Cause Analysis (ADB Issue):**

Classification: Configuration

Evidence:
- Device detected at USB level: `lsusb` shows "Bus 001 Device 015: ID 2d95:6001 vivo I2202"
- Device works on Windows laptop (same phone, different OS)
- ADB installed but `adb devices` shows empty list
- Missing udev rules: `/etc/udev/rules.d/51-android.rules` does not exist
- User not in `plugdev` group: `groups` output shows "seq_vishnu sudo users ollama docker"

Why: Linux requires explicit USB permissions via udev rules, unlike Windows which 
handles this automatically through driver installation.

Where: System-level USB device permissions configuration

How: Missing udev rules prevent non-root users from accessing Android devices via ADB

Reproduction:
1. Connect Android device via USB
2. Run `adb devices`
3. Result: Empty device list (no permissions to access USB device)

**Implementation:**

Created comprehensive documentation:
1. `FLUTTER_MIGRATION_PLAN.md` - Complete migration strategy with:
   - System resource analysis and storage optimization
   - Flutter installation steps
   - Migration phases (5 weeks)
   - Development workflow
   - Performance optimization
   - Security considerations

2. `ADB_LINUX_FIX_GUIDE.md` - Detailed ADB troubleshooting with:
   - Root cause explanation (Linux vs Windows USB handling)
   - Step-by-step manual fix procedures
   - Automated fix script
   - Common issues and solutions
   - Testing procedures

3. `fix-adb.sh` - Automated script that:
   - Detects connected Android device vendor ID (vivo: 2d95)
   - Creates udev rules with correct permissions
   - Adds user to plugdev group
   - Resets ADB server
   - Tests connection

**Impact:**

Performance:
- Flutter provides better performance than React Native
- Native compilation vs JavaScript bridge
- Smaller APK sizes with proper optimization

Storage:
- Requires 25-30GB for complete Flutter development environment
- Current available: 53GB (marginal, requires cleanup)
- Cleanup target: Free 15-20GB before installation

Maintainability:
- Single codebase for Android/iOS (future)
- Better tooling and hot reload
- Stronger type safety with Dart

Security:
- Proper udev rules prevent running ADB as root
- Secure storage for tokens
- Certificate pinning for API calls

UX:
- Native performance and animations
- Better SMS reading integration
- Smoother user experience

**Rollback Strategy:**
- Keep existing `mobile/` directory as `mobile_react_native_backup`
- Can revert to React Native if Flutter migration fails
- No breaking changes to backend API

**Next Actions Required:**

1. **IMMEDIATE - Fix ADB (Priority: CRITICAL)**
   ```bash
   cd /home/seq_vishnu/WORK/RnD/expenze
   ./fix-adb.sh
   # Follow prompts, allow USB debugging on phone
   # Logout/login if added to plugdev group
   ```

2. **IMMEDIATE - Storage Cleanup (Priority: CRITICAL)**
   ```bash
   # Clean package caches
   sudo apt clean && sudo apt autoclean && sudo apt autoremove
   npm cache clean --force
   
   # Find and remove large unnecessary files
   du -h ~ | sort -rh | head -20
   
   # Target: Free 15-20GB
   ```

3. **After Cleanup - Install Flutter**
   ```bash
   cd ~/
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz
   tar xf flutter_linux_3.27.1-stable.tar.xz
   rm flutter_linux_3.27.1-stable.tar.xz
   echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   flutter doctor -v
   ```

4. **Verify Setup**
   ```bash
   flutter doctor -v
   flutter doctor --android-licenses
   adb devices  # Should show vivo device
   ```

5. **Create Flutter Project**
   ```bash
   cd /home/seq_vishnu/WORK/RnD/expenze
   cp -r mobile mobile_react_native_backup
   flutter create expenze_flutter
   ```

**Risk Assessment:**

High Risks:
- Storage exhaustion during build (Mitigation: Mandatory cleanup + monitoring)
- ADB configuration issues (Mitigation: Automated fix script provided)

Medium Risks:
- Learning curve for Flutter/Dart (Mitigation: Phased migration, 5-week plan)
- SMS permission changes Android 10+ (Mitigation: Use telephony package)

Low Risks:
- API compatibility (Backend already REST-based)
- Performance issues (Flutter is performant by default)

**Success Criteria:**
- ADB detects device: `adb devices` shows "device" status
- Flutter installed: `flutter doctor` shows all checkmarks
- Storage usage: <75% after cleanup
- First Flutter app runs on physical device
- SMS reading functionality works

**Documentation:**
- Technical specification: `docs/FLUTTER_MIGRATION_PLAN.md`
- Technical specification: `docs/FLUTTER_MIGRATION_PLAN.txt`
- Troubleshooting guide: `docs/ADB_LINUX_FIX_GUIDE.md`
- Automation script: `fix-adb.sh`

**Timeline:**
- ADB Fix: 30 minutes
- Storage Cleanup: 1-2 hours
- Flutter Installation: 1 hour
- Project Setup: 2 hours
- Full Migration: 4-5 weeks

**Cost Analysis:**
- Time: 4-5 weeks development
- Storage: 25-30GB disk space
- Monetary: $0 (all tools are free and open source)

**References:**
- Flutter Documentation: https://docs.flutter.dev/
- Android Developer ADB Guide: https://developer.android.com/tools/adb
- Device detected: vivo I2202 (Vendor ID: 2d95)

## [2026-02-12] Flutter Background Installation & ADB Troubleshooting

**Change Type:** Patch

**Decision Made:**
Started Flutter SDK installation in the background to save time while resolving the persistent ADB connection issue with the Vivo device.

**Action Taken:**
1. Created `install-flutter-bg.sh` to automate Flutter download and setup.
2. Started background installation (PID logged in `flutter_install_start.log`).
3. Verified Vivo device (2d95:6001) is visible on USB bus with 0666 permissions.
4. Attempted manual ADB server resets and VID registration.

**Current Blockers:**
- `adb devices` returns empty list even with correct permissions and MTP enabled.
- Identifying Vivo-specific security settings (Security Debugging/Install via USB) that might be blocking the ADB handshake.

**Next Steps:**
- Monitor `/home/seq_vishnu/WORK/RnD/expenze/flutter_install.log` for installation status.
- Finalize ADB connection by toggling phone-specific security settings.

## [2026-02-12] Flutter Installation Complete & ADB Mode Shift

**Change Type:** Patch

**Status Update:**
- Flutter SDK installation finished successfully.
- Verified with `flutter doctor` in background log.
- Path added to `.bashrc`: `export PATH="$HOME/flutter/bin:$PATH"`

**ADB Status:**
- Identified that the Vivo device changed Product ID from `6001` (ADB enabled) to `6005` (No ADB interface).
- This shift is the reason for the empty `adb devices` list.
- User needs to switch USB modes on the phone to re-enable the ADB interface.

## [2026-02-12] Flutter Application Created Successfully

**Change Type:** Major

**Decision Made:**
Successfully created Flutter mobile application after resolving all system prerequisites and ADB connectivity issues.

**Implementation:**
1. Backed up React Native app to `mobile_react_native_backup`
2. Created new Flutter project with organization ID: `com.expenze`
3. Project name: `expenze_mobile`
4. Location: `/home/seq_vishnu/WORK/RnD/expenze/mobile`

**System Verification:**
- Flutter detects Vivo I2202 device (1592460721000B5) ✅
- Android API 34 support confirmed ✅
- Device shows as `device` status (authorized) ✅

**Known Issues:**
- Java 21 vs Gradle 8.3 compatibility warning (non-blocking)
- Can be resolved by updating Gradle to 8.4-8.7 range if needed

**Next Steps:**
1. Set up project structure following clean architecture
2. Configure dependencies (dio, provider, flutter_secure_storage, telephony)
3. Implement authentication flow
4. Migrate SMS reading functionality
5. Test on physical device

**Impact:**
- Performance: Native compilation, better performance than React Native
- Maintainability: Single codebase, strong typing with Dart
- Development: Hot reload enabled for rapid iteration
- Storage: Initial project size ~50MB, manageable within available space

**Rollback Strategy:**
- Original React Native app preserved in `mobile_react_native_backup`
- Can revert by renaming directories if needed

**Success Criteria Met:**
- ✅ ADB connection established
- ✅ Flutter SDK installed and configured
- ✅ Device detected and authorized
- ✅ Project created successfully
- ✅ Storage usage within acceptable limits

## [2026-02-12] Flutter Mobile App - Initial Implementation Complete

**Change Type:** Major

**Decision Made:**
Successfully created Flutter mobile application with production-ready architecture, authentication flow, and dashboard screen. App name configured as "Expenze" and running on physical device.

**Implementation:**
1. **Project Structure:**
   - Clean Architecture (core, data, presentation layers)
   - Provider pattern for state management
   - Secure storage for authentication tokens
   - Dio HTTP client with interceptors

2. **Screens Implemented:**
   - Login Screen - Full authentication UI with validation
   - Dashboard Screen - Financial overview with stats cards
   - Auth Wrapper - Auto-navigation based on login state

3. **Core Services:**
   - ApiService - HTTP client with auth headers
   - AuthProvider - Authentication state management
   - Theme system matching frontend design

4. **Configuration:**
   - App name: "Expenze" (updated in AndroidManifest.xml)
   - All dependencies installed and working
   - Import paths fixed for proper module resolution

**Technical Details:**
- Flutter SDK: 3.27.1
- Dart SDK: 3.6.0
- Android API: 34
- Device: Vivo I2202 (Android 14)

**Impact:**
- Performance: Native compilation, 60 FPS capable
- Maintainability: Clean architecture, easy to extend
- Security: Encrypted token storage, secure API calls
- Development: Hot reload enabled for rapid iteration

**Next Steps:**
1. Connect to backend API (update base URL)
2. Implement real data loading in Dashboard
3. Add charts (spending trend, category breakdown)
4. Create Monthly Plan screen
5. Implement SMS import functionality

**Rollback Strategy:**
- React Native app backed up in `mobile_react_native_backup`
- Can revert by renaming directories if needed

**Success Criteria Met:**
- ✅ App builds successfully
- ✅ App runs on physical device
- ✅ Authentication flow implemented
- ✅ Dashboard displays correctly
- ✅ Hot reload ready for development
- ✅ Production-ready code structure

## [2026-02-12] Offline-First Session Management & UI Refinement

**Change Type:** Major

**Decision Made:**
Refactored authentication and session management to support robust offline-first "multiple type logins" without data loss on standard logout. Upgraded all dependencies to latest stable versions and implemented a premium iOS-like aesthetic using the Inter font family.

**Implementation:**
1. **Auth Session Logic:**
   - Logout now preserves the local database, enabling user data retention across sessions.
   - Authentication now rigorously syncs user profiles with both SharedPreferences and SQLite `users` table.
   - initialization flow refined to restore full user context from persistent storage.
2. **Dependency Management:**
   - Upgraded all packages to their latest stable versions (`flutter pub upgrade --major-versions`).
   - Integrated `google_fonts` for premium typography.
3. **Premium Design System:**
   - Switched primary font to **Inter** for high legibility and premium feel.
   - Refined `AppTheme` with modernized input decorations, button styles, and card layouts.
4. **Code Quality & Architecture:**
   - Finalized removal of `ApiService` dependencies from core flows (`main.dart`, `ResetPasswordScreen`).
   - Resolved multiple lint errors and naming inconsistencies in the `regular_payments` module.

**Impact:**
- Performance: Improved dependency stability and local data access patterns.
- Security: Robust local session handling and Google Identity parity.
- UX: Premium typography and refined UI components provide an iOS-standard experience.
- Maintainability: Dependency versions are now up-to-date, reducing technical debt.

**Rollback Strategy:**
- Git commits track pre-upgrade state.
- Database Version 2 migration is backward compatible for columns.
- **Hotfix:** Resolved `google_sign_in` 7.x migration issues by switching to `GoogleSignIn.instance`, adding mandatory `initialize()` call, and migrating `signIn()` to `authenticate()` with stream-based identity capture.
- **Runtime Fix:** Handled `clientConfigurationError` on Android where `serverClientId` is missing. Initialization is now non-fatal, allowing the app to start cleanly even if Google Sign-In is misconfigured. Created `docs/GOOGLE_SIGNIN_SETUP.md` for user guidance.

## [2026-02-12] Identity, Authorization & UI Enhancement

**Change Type:** Major

**Decision Made:**
Implemented a robust, local database-backed identity system with personalized greetings, full name support, and premium UI refinements. This establishes a "Digital Wallet" identity where user data is correctly linked to verified local accounts.

**Implementation:**
1. **Database Schema Upgrade (v4):**
   - Added `full_name` and `password` columns to the `users` table.
   - Refactored `DatabaseHelper` to support structured registration and profile management.
2. **Identity Support:**
   - Modified `AuthProvider` to handle `fullName` and local password verification.
   - Enhanced `RegisterScreen` with a "Full Name" field and robust input validation.
   - Updated `ProfileScreen` to allow manual editing of `fullName` and `username`.
3. **UI/UX Polish:**
   - Replaced "Good Morning" with a dynamic `_getTimeBasedGreeting()` system.
   - Prioritized `fullName` over `username` in greetings for deep personalization.
   - Improved the "Digital Wallet" aesthetic in `ProfileScreen` with glassmorphic elements.
4. **Resiliency & Fixes:**
   - Resolved `google_sign_in` 7.1.1 constructor errors by migrating to the `instance` singleton pattern.
   - Sanitized input fields and improved error feedback in Auth flows.

**Impact:**
- UX: Personalization and premium design trends increase user engagement.
- Security: Real passcode/password verification for local accounts.
- Performance: Efficient SQLite queries for identity restoration.

**Rollback Strategy:**
- Database schema preserves existing columns; revert `AuthProvider` to identity-agnostic mode if needed.

## [2026-02-13] Automated SMS Expense Tracking Planning

**Change Type:** Minor

**Decision Made:**
Initiated planning and documentation for the "SMS Automated Import" feature. This feature aims to read native Android SMS messages to automate expense detection, reducing friction for users.

**Implementation:**
1. Created comprehensive documentation suite in `docs/`:
   - `rfc-sms-import.md/.txt`: Proposal for the new capability.
   - `business-overview-sms-import.md/.txt`: Non-technical value proposition.
   - `technical-specification-sms-import.md/.txt`: Architectural details and data flow.
   - `threat-model-sms-import.md/.txt`: Security analysis of SMS reading.
   - `compliance-checklist-sms-import.md/.txt`: Privacy and data handling verification.
   - `release-checklist.md/.txt`: Pre-deployment validation steps.
2. Built `SmsService` with `another_telephony` (switched from discontinued `telephony` to fix namespace errors) and `permission_handler`.
3. Integrated "Sync from Inbox" button in `SmsImportScreen`.
4. Resolved Gradle `afterEvaluate` error by migrating to full Plugin DSL:
   - Updated `settings.gradle` to use `dev.flutter.flutter-gradle-plugin`.
   - Updated `app/build.gradle` to use `org.jetbrains.kotlin.android`.
5. Performed `flutter clean` to remove build cache remnants.

**Impact:**
- UX: One-tap synchronization of recent transactions.
- Security: Local-only parsing; sensitive data never leaves the device.
- Build: Corrected alignment between legacy and modern Flutter Gradle plugin approaches for AGP 8.3+.

**Rollback Strategy:**
- Feature can be disabled via UI/Permissions. Gradle changes are backward compatible with standard Flutter 3.16+ templates.

Date: 2026-02-13

## [2026-02-16] Data Connectivity & Business Logic Implementation

**Change Type:** Major

**Decision Made:**
Connected the application's UI screens to the real SQLite backend, replacing all dummy values with dynamic calculations. Implemented advanced analytics queries and cross-screen data synchronization via Provider.

**Implementation:**
1. **ExpenseRepository Enhancements:**
   - Added `getAnalyticsSummary(int months)` for calculating averages and peaks using SQL aggregations.
   - Refined `getTrends()` to ensure chronological data series for charts.
   - Improved `getCategoryBreakdown()` to include joined icon and color data.
2. **Provider State Evolution:**
   - Added reactive state for `avgMonthlySpent` and `maxMonthlySpent`.
   - Updated `loadTrends()` to fetch complete analytical context.
3. **Analytics UI Overhaul:**
   - Connected Insight cards to real provider data.
   - Dynamically generated Top Categories list from DB records instead of placeholders.
   - Fixed trend chart to display oldest to newest data correctly.
4. **Dashboard Integration:**
   - Linked "Details" and "Add" quick actions to their respective screens.
   - Implemented dynamic category builders using database-stored icons (emojis) and color codes.
   - Enabled real-time refresh via pull-to-refresh and direct navigation.
5. **Architectural Improvements:**
   - Updated `MainNavigationWrapper` to support `initialIndex` for deep-linking (e.g., from Dashboard to Analytics).
   - Standardized hex-to-color conversion for user-defined category colors.

**Impact:**
- UX: Users now see accurate financial reflections across the app.
- Performance: SQL-level aggregations ensure fast UI updates even with growing transaction lists.
- Maintainability: Centralized business logic in Provider/Repository layers prevents data drift.

**Rollback Strategy:**
- Critical logic is capped within new methods; revert UI bindings to previous provider fields if data mismatch occurs.
- UI placeholders are preserved in comments for rapid restoration.

Date: 2026-02-16

## [2026-02-16] UI Fixes & Regular Payment Synchronization

**Change Type:** Patch

**Decision Made:**
Resolved discrepancy where "Regular Payments" were not reflecting on the dashboard and fixed issues with analytics charts not populating for new users.

**Implementation:**
1. **Regular Payment Sync:**
   - Implemented `syncRegularPayments` in `ExpenseRepository` to automatically instantiate active bills as monthly expenses.
   - Integrated sync logic into `ExpenseProvider.loadMonthData` to ensure budget planning is up-to-date.
2. **Analytics Enhancements:**
   - Updated `AnalyticsScreen` line chart to show both **Planned** (dashed) and **Actual** (solid) trends.
   - Refined `maxY` logic to ensure charts have a visible scale even when spending is zero.
   - Updated **Insight Cards** to fall back to planned metrics if actual spending hasn't started, ensuring meaningful feedback.
3. **Dashboard Refinement:**
   - Updated Category list to prioritize showing **Planned** amounts if **Actual** spending is zero, correctly reflecting bills and dues.
   - Modified repository queries to include categories with planned-only amounts.

**Impact:**
- UX: Immediate visual confirmation of regular bills in the monthly budget.
- Accuracy: Better alignment between the "Bills/Regular Payments" module and the main Dashboard/Analytics.

Date: 2026-02-16

## [2026-02-16] UX & Utility Suite Implementation

**Change Type:** Major

**Decision Made:**
Implemented a comprehensive Dark Mode system and a versatile Utility suite (Notes & Reminders) to enhance user personalization and everyday financial tracking beyond structured expenses. Updated the entire UI to use premium background decorations and fixed dashboard inconsistencies.

**Implementation:**
1. **Theming System:**
    - Created `ThemeProvider` with `SharedPreferences` persistence for dark mode.
    - Added `darkBackgroundDecoration` and `darkTheme` configuration to `AppTheme`.
    - Integrated logic in `main.dart` to reactively switch themes without app restart.
    - Updated all major screens (`Dashboard`, `Profile`, `Analytics`, `MonthPlan`, `Categories`, `RegularPayments`, `SmsImport`) to use theme-aware backgrounds and card colors.
2. **Utility Features (Notes & Reminders):**
    - Created `Note` model and `NoteRepository`.
    - Migrated database to **v7** to include the `notes` table.
    - Implemented `NoteProvider` for state management with Pinning and Date-based filtering.
    - Created a high-performance `NotesScreen` with modal bottom sheets for creation and editing.
3. **UI Refinement & Dashboard Fixes:**
    - Renamed "Add" to "Plan" on Dashboard for better context.
    - Renamed "Cats" to "Types" for user clarity.
    - Replaced the generic SMS icon with `LucideIcons.mail` as requested.
    - Removed redundant "Bills" section from Dashboard (now exclusively in the Regular Payments tab).
4. **Consistency:**
    - Standardized card aesthetics across all screens using `Theme.of(context).cardTheme.color`.
    - Fixed linting issues related to unused imports and variables.

**Impact:**
- **UX**: Premium, modern feel with complete personalization options.
- **Accessibility**: Dark mode support improves usability in varying light conditions.
- **Functionality**: Versatile notes allow users to track financial thoughts alongside transactions.
- **Maintainability**: Centralized theme and utility logic prevents code duplication.

**Rollback Strategy:**
- Revert database to v6 (drops notes table).
- Reset theme preference in SharedPreferences.

Date: 2026-02-16

## [2026-02-16] Theme Transition Bug Fix

**Change Type:** Patch

**Decision Made:**
Resolved a critical Flutter framework exception (`Failed to interpolate TextStyles with different inherit values`) that occurred during theme transitions (Light <-> Dark) when using custom Google Fonts.

**Implementation:**
1. **AppTheme Normalization**: 
    - Explicitly set `inherit: true` for all key `TextStyles` in `AppTheme.dart` (`labelLarge`, `bodyLarge`, `displayLarge`, etc.).
    - Unified `ElevatedButtonThemeData` across both light and dark themes with explicit `textStyle` definitions.
    - Ensures that Flutter's animation engine can smoothly interpolate between theme states without encountering mismatched inheritance flags.
2. **Global Consistency**:
    - Applied these changes to both `lightTheme` and `darkTheme` to prevent future regressions during theme switching.

**Impact:**
- **Reliability**: Eliminates app crashes/exceptions during theme changes.
- **UX**: Smooth transitions between Light and Dark modes.

Date: 2026-02-16

## [2026-02-16] Theme Consistency & Text Visibility Refinements

**Change Type:** Patch

**Decision Made:**
Implemented system-wide text visibility fixes to ensure all UI elements are readable across both Light and Dark themes. Standardized the use of dynamic text colors and refined background decorations.

**Implementation:**
1. **Theming Utilities Refinement**:
    - Introduced `AppTheme.getTextColor(context)` to dynamically retrieve primary and secondary text colors based on theme brightness.
    - Updated `AppTheme.inputDecoration` to accept `BuildContext` for theme-aware hint styling.
    - Ensured explicit `inherit: true` for all `GoogleFonts` styles in `AppTheme.dart` to prevent interpolation errors.
2. **Screen-level Updates**:
    - **DashboardScreen**: Refactored to use dynamic text colors for greetings, stats cards, and category items. Fixed background decoration placement to prevent overflow.
    - **AnalyticsScreen**: Standardized text colors for chart labels, insight cards, and category breakdowns. Improved chart contrast.
    - **NotesScreen**: Updated empty state and card styling for theme consistency. Applied modern background decorations.
    - **ProfileScreen**: Fixed hardcoded color references and corrected `BoxDecoration` border parameter error.
    - **CategoriesScreen**: Enhanced category list item visibility with theme-aware colors.
3. **Bug Fixes**:
    - Resolved `Failed to interpolate TextStyles` error by normalizing `inherit` values.
    - Fixed `RenderFlex overflow` issues by refining background decoration application.

**Impact:**
- **UX**: High readability in all lighting conditions and theme modes.
- **Reliability**: Eliminated framework exceptions during theme switching.
- **Consistency**: Unified aesthetic across all core screens.

Date: 2026-02-16

## [2026-02-16] Regular Payments Enhancement & Quick Actions

**Change Type:** Minor

**Decision Made:**
Enhanced the "Regular Payments" module to allow tracking of bill status and detailed logs. Added a "Quick Add" feature to the Dashboard for faster expense entry.

**Implementation:**
1. **Regular Payments Upgrade**:
    - **Database Migration (v8)**: Added `status` and `status_description` columns to the `regular_payments` table.
    - **Model & Provider**: Updated `RegularPayment` model with `copyWith` and `status` fields. Added `updatePayment` method to `RegularPaymentProvider`.
    - **UI Refinement**: Redesigned `RegularPaymentsScreen` with a modal dialog for both adding and editing. Added status indicators and description support to payment cards.
2. **Dashboard Quick Actions**:
    - **New Feature**: Added a **FloatingActionButton** to the Dashboard for immediate expense entry.
    - **Implementation**: Created a "Quick Expense" modal bottom sheet on the Dashboard that integrates with `ExpenseProvider` and `CategoryProvider`.
3. **Maintenance**:
    - Removed unused imports and simplified screen layouts.
    - Updated `.gitignore` to exclude `test/` artifacts.

**Impact:**
- **UX**: Improved bill management transparency and reduced friction for adding expenses.
- **Functionality**: Users can now document payment reasons or delay statuses (e.g., "Awaiting Salary").
- **Maintainability**: Cleaner codebase with reduced unused dependencies.

Date: 2026-02-16

Date: 2026-02-16

## [2026-02-16] Spending Limit & Budget Planner Refinements

**Change Type:** Minor

**Decision Made:**
Enhanced the "Monthly Spending Limit" functionality to ensure it is prioritized for all remaining balance calculations. Refined the Budget Planner screen to remove redundant input forms and improved its visual aesthetic with a premium gradient header.

**Implementation:**
1. **Spending Limit Integration**:
    - Modified `ExpenseRepository.getMonthSummary` and `getMonthlyLimit` to correctly fetch the limit from `month_plans` with a fallback to user default budget.
    - Updated `ExpenseProvider.loadMonthData` to prioritize the limit over the planned sum for "Remaining" calculations.
    - Integrated limit editing dialogs into both `DashboardScreen` and `MonthPlanScreen`.
2. **Budget Planner (MonthPlanScreen) UI Update**:
    - Removed the "Plan New Expense" form as per user request (logic now centered on tracking and limit adjustment).
    - Implemented a premium gradient summary header to match the Dashboard's aesthetic.
    - Fixed color inconsistencies and standardized theme-aware text/card styling.
3. **Bug Fixes**:
    - Corrected issues where the spending limit was not reflected in the total budget calculations.
    - Resolved UI flickering/mismatch in background decorations.

**Impact:**
- **UX**: Cleaner, more focused Budget Planner. More intuitive budget tracking using explicit limits.
- **Accuracy**: Financial stats now correctly track against user-defined goals.
- **Consistency**: Universal look and feel across core screens.

Date: 2026-02-16

## [2026-02-16] Brand Realignment & App Renaming

**Change Type:** Minor

**Decision Made:**
Updated the application's user-facing name from `expenze_mobile` to `Expenze` across all supported platforms (Android, iOS, Web) to ensure brand consistency and a more professional presentation.

**Implementation:**
1. **Android**: Modified `android/app/src/main/AndroidManifest.xml` to set `android:label="Expenze"`.
2. **iOS**: Updated `ios/Runner/Info.plist` to set `CFBundleDisplayName` and `CFBundleName` to `Expenze`.
3. **Web**: 
    - Updated `web/manifest.json` with new name and short_name.
    - Updated `web/index.html` title and iOS meta tags.
4. **App Level**: Verified `MaterialApp` title is set correctly to `Expenze`.

**Impact:**
- **UX/Branding**: Improved user recall and professional look on the device home screen and browser tabs.
- **Consistency**: Unified brand identity across all platforms.

Date: 2026-02-16

## [2026-02-16] UI Reorganization: Centralized App Settings

**Change Type:** Minor

**Decision Made:**
Relocated the Dark Mode toggle from the Profile screen to a newly created dedicated Settings screen. This improves the architectural separation between user account details and application-wide preferences.

**Implementation:**
1. **New Screen**: Created `lib/presentation/screens/settings/settings_screen.dart` to host application settings, starting with Appearance (Dark Mode).
2. **Navigation Update**: Updated `lib/presentation/navigation/main_navigation_wrapper.dart` to replace the "Notes" tab with the "Settings" tab. 
3. **Profile Refactor**: Removed the appearance management section from `ProfileScreen` to keep it focused on account identity.
4. **Cleanup**: Resolved lint errors related to unused imports and missing type arguments during the transition.

**Impact:**
- **UX**: More intuitive navigation. Users now look for "Settings" to change app behavior rather than searching within their profile.
- **Maintainability**: Clearer separation of concerns makes it easier to add future global settings (notifications, currency, etc.).

Date: 2026-02-16

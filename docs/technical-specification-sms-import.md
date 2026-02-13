# Technical Specification: SMS Automated Import

## System Overview
The SMS Import module extends the current `SmsImportScreen` by adding a direct connection to the Android Telephony Content Provider. It leverages the `telephony` package for message retrieval and the existing `DetectedExpense` model for UI presentation.

## Architecture Diagram (ASCII)
```
[ SmsImportScreen ]
      |
      v
[ SmsService (Telephony) ] <---> [ Android SMS Provider ]
      |
      v
[ Regex Engine ]
      |
      v
[ List<DetectedExpense> ]
```

## Component Breakdown
- **SmsService**: A singleton service that wraps the `telephony` plugin. It handles permission checks and message collection.
- **PermissionHandler**: Used to manage and verify system-level SMS permissions.
- **Regex Engine**: Enhanced version of the current parsing logic to filter bank-specific keywords.

## Data Flow
1. User triggers `syncFromInbox()`.
2. `SmsService` verifies `Permission.sms.isGranted`.
3. `telephony.getInboxMessages` is called with filtering.
4. Messages are passed to `_extractExpenseFromSms()`.
5. Map of parsed data is converted to `DetectedExpense` objects.
6. Local state in `SmsImportScreen` is updated, triggering a UI rebuild.

## API Contracts
N/A - Direct Native Content Provider access.

## Validation Rules
- **Regex**: Must match amount pattern (₹/Rs./INR followed by digits).
- **Date**: Messages older than 30 days are ignored by default to prevent clutter.
- **Type**: Only "received" messages are considered.

## Error Handling
- **No Permissions**: Triggers a system dialog followed by a "Rationale" snackbar if denied.
- **No Messages**: Empty state UI shown.
- **Parse Failure**: Logged to console; raw message is discarded.

## Schema Changes
None.

## Security Model
- **Permission Gating**: Runtime permission request (Android 6.0+).
- **Data Privacy**: No SMS content is stored permanently unless the user explicitly saves it as an expense.
- **Local Processing**: All parsing happens in-memory on the device.

## Performance Analysis
- Frequency: On-demand (button press).
- Complexity: O(N) where N is the number of messages scanned (capped at 50).
- Memory: Minimal, only holding transient strings.

## Scalability Plan
- Future: Add support for background listeners for real-time tracking.

## Monitoring Plan
- Logging: Log count of messages scanned vs. expenses detected.

## Deployment Plan
1. Add `READ_SMS` and `RECEIVE_SMS` to Android manifest.
2. Bump `telephony` dependency.
3. Distribution via APK/Play Store.

## Rollback Plan
- Disable the "Sync" button in UI.
- Remove permissions from manifest.

Date: 2026-02-13

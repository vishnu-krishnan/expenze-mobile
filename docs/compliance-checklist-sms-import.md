# Compliance Checklist: SMS Automated Import

## Data Classification
- **Sensitive Personal Data**: Financial transaction history, Bank names, Partial account numbers (if in SMS).
- **Processing Type**: Local-Only (Edge Processing).

## Checklist

### Data Privacy (GDPR/Local Laws)
- [x] **Data Minimization**: Only 50 recent messages scanned.
- [x] **Purpose Limitation**: Used only for expense tracking proposals.
- [x] **No Exfiltration**: Verified that SMS content is never sent to a remote API.
- [x] **User Consent**: Runtime permission request + explicit "Sync" button.

### Encryption
- [x] **In-Transit**: N/A (Local processing).
- [x] **At-Rest**: Once saved as an expense, data is stored in a private SQLite database.

### Access Controls
- [x] **Least Privilege**: Only `READ_SMS` permission requested.
- [x] **Revocability**: User can revoke SMS permission at any time in system settings.

### Audit & Logging
- [x] **Audit Log**: Activity Log tracks the addition of this sensitive capability.
- [x] **Transaction Log**: Individual expense saves are logged in the SQLite ledger.

### Deletion Process
- [x] **Manual**: User can delete any imported expense.
- [x] **Purge**: Resetting app data wipes all stored expenses and revokes permissions.

Date: 2026-02-13

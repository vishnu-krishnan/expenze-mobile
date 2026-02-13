# Threat Model: SMS Automated Import

## System Overview
The SMS Import feature reads private user messages to automate financial logging. This introduces a sensitive attack surface.

## Attack Surface
- **Android SMS Provider**: Compromised or hijacked message content.
- **Application Memory**: Temporary storage of parsed SMS content.
- **Regex Logic**: Potential for "Regex Denial of Service" or bypass via malicious SMS formatting.

## STRIDE Analysis

### Spoofing
- **Risk**: A malicious app could potentially spoof SMS intent if not correctly handled.
- **Mitigation**: Using the official `telephony` package which interacts directly with the system Content Resolver, not general intents.

### Tampering
- **Risk**: Malicious SMS could be crafted to inject data into the expense ledger.
- **Mitigation**: All detected expenses require manual review and confirmation by the user before being committed to the database.

### Repudiation
- **Risk**: User claims they didn't authorize a scan.
- **Mitigation**: Explicit button click to trigger sync and system-level permission dialog.

### Information Disclosure (High Risk)
- **Risk**: Sensitive SMS content (OTPs, private chats) being read by the app.
- **Mitigation**:
  1. No data is sent to ANY server.
  2. Regex filters specifically for transaction patterns.
  3. OTPs (typically 6-digit codes) are ignored by filters looking for currency amounts and merchant names.

### Denial of Service
- **Risk**: Oversized SMS or infinite message history causing app crash.
- **Mitigation**: Cap at 50 messages and 30-day lookback.

### Elevation of Privilege
- **Risk**: App uses SMS permission to perform unauthorized actions.
- **Mitigation**: Strict "Least Privilege" implementation - `READ_SMS` is the only active scope during sync.

## Residual Risk
The app has the *capability* to read all SMS messages. This is a baseline risk of any finance app. Trust is established via "Local-Only" architecture.

Date: 2026-02-13

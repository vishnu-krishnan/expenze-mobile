# Threat Model - Notes & Reminders

### System overview
Storage and retrieval of user-provided text (Notes) and scheduled reminders.

### Attack surface
- **SQLite Database**: Rooted devices could potentially access the raw database file.
- **Input fields**: Potential for large input to cause denial of service if not capped.

### STRIDE analysis
- **Spoofing**: Not applicable (local data).
- **Tampering**: Mitigated by standard app sandboxing.
- **Repudiation**: Not applicable.
- **Information Disclosure**: Primary risk on rooted devices.
- **Denial of Service**: Mitigated by input caps and efficient list building.
- **Elevation of Privilege**: Not applicable.

### Mitigations
- Data is stored in the application's private sandboxed directory.
- No PII (unless entered by user) is handled by the Notes system.
- Permission-gated access to notifications for reminders.

### Residual risk
- Users on rooted devices or devices with compromised security may have their notes exposed to local malware. 
- **Recommendation**: Do not store plain-text passwords or high-sensitivity secrets in notes.

**Security must be designed.**

Date: 2026-02-16

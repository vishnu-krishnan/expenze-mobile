# Business Overview: Smart Spending Limit Carry-over

Problem:
Users frequently set a monthly spending limit (budget) once and expect it to persist for subsequent months unless they manually change it. The previous system required a limit to be set every month, defaulting to 0 or a global default budget if forgotten, which led to incorrect "remaining balance" calculations.

Objective:
Implement an intelligent carry-over mechanism for spending limits that ensures the most recently defined budget remains active for all future months until explicitly updated.

Feature Summary:
- Persistence: Setting a limit for January automatically applies it to February, March, etc., if no new limit is set.
- Dynamic Retrieval: Calculations for "Remaining Balance" now search backwards in time for the most recent valid limit.
- Fallback Safety: Continues to use the global user default budget as the final baseline.

Business Value:
- Reduced friction for long-term users.
- Improved accuracy in financial planning.
- Enhanced "set and forget" user experience.

Risks:
- Users might forget they set a limit months ago; mitigated by clear UI indicators of active limits.

Cost Implications:
- Minimal database overhead (single sub-query improvement).

Timeline:
- Implemented and verified: 2026-02-17

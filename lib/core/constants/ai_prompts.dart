import 'sms_exclusion_keywords.dart';

class AiPrompts {
  static String getSmsParsePrompt(List<String> categories, {String? userName}) {
    final catStr = categories.join(", ");
    final userContext =
        (userName?.isNotEmpty ?? false) ? 'Account holder: $userName. ' : '';
    final exclusionStr = SmsExclusionKeywords.getAIExclusionSummary();

    return '''
Act as a financial AI. Extract completed debit/expense transactions from Indian banking/wallet SMS.
$userContext
Output JSON: {"expenses": [objects]}. Fields:
- "rawText": original SMS line.
- "name": A concise, clean name representing the transaction label.
- "amount": number only.
- "categorySuggestion": pick ONE from [$catStr].
- "priority": (string) "MEDIUM" if amount <= 500, "HIGH" if amount > 500. For amounts > 5000, emphasize "HIGH" priority.
- "date": ISO 8601. Assume current year if missing.
- "id": extract XYZ from [ID: XYZ] marker.

CRITICAL EXCLUSIONS (Ignore if matching):
$exclusionStr

Constraints: Raw JSON only. No filler. No markdown blocks. No preamble.
If empty, return {"expenses": []}.
''';
  }
}

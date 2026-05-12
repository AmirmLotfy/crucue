export interface SafetyCheck {
  isHighRisk: boolean;
  riskType?: string;
  crisisNote: string;
}

const HIGH_RISK_PATTERNS = [
  /\b(suicid|self.?harm|hurt.{0,20}(self|myself|them|themselves))\b/i,
  /\b(kill.{0,10}(self|myself|them|themselves))\b/i,
  /\b(overdos|cutting\s+myself|cutting\s+themselves)\b/i,
  /\b(abuse|being abused|hitting them|hit them)\b/i,
  /\b(danger(ous)?|emergency|crisis|911|hospital)\b/i,
  /\b(threaten|threatened|violent|violence)\b/i,
];

const CRISIS_RESOURCES = `If there is immediate risk of harm, please call emergency services (911) or contact the 988 Suicide & Crisis Lifeline by calling or texting 988. You can also text HOME to 741741 to reach the Crisis Text Line.`;

/**
 * Check user-submitted text for high-risk content patterns.
 * Returns a flag and crisis note if risk is detected.
 */
export function checkSafety(text: string): SafetyCheck {
  const lower = text.toLowerCase();

  for (const pattern of HIGH_RISK_PATTERNS) {
    if (pattern.test(lower)) {
      return {
        isHighRisk: true,
        riskType: "potential_harm",
        crisisNote: CRISIS_RESOURCES,
      };
    }
  }

  return {
    isHighRisk: false,
    crisisNote: "This is supportive guidance, not professional care. For serious concerns, please consult a qualified professional.",
  };
}

/**
 * Apply safety check to a generated plan.
 * Overrides escalation_flag and safety_note if high risk detected.
 */
export function applySafetyToResponse(
  response: Record<string, unknown>,
  userInput: string,
  aiResponse: string
): Record<string, unknown> {
  const inputCheck = checkSafety(userInput);
  const outputCheck = checkSafety(aiResponse);

  if (inputCheck.isHighRisk || outputCheck.isHighRisk) {
    return {
      ...response,
      escalation_flag: true,
      safety_note: CRISIS_RESOURCES,
    };
  }

  return response;
}

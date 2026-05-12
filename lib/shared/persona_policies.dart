/// Persona-specific AI policy packs.
///
/// One policy per persona type. These are serialized and sent as
/// [policyOverrides] to Cloud Functions so the AI engine adjusts
/// tone, suggestion style, safety thresholds, and escalation logic
/// without changing the core prompt architecture.
///
/// IMPORTANT: This is configuration, not roleplay.
/// The AI uses one shared engine. These packs adjust behaviour,
/// not identity.
class PersonaPolicy {
  final String personaType;
  final String toneGuidance;
  final List<String> suggestionTypes;
  final String safetyBoundaries;
  final String escalationThreshold;
  final String messageDraftStyle;
  final List<String> routineExamples;

  const PersonaPolicy({
    required this.personaType,
    required this.toneGuidance,
    required this.suggestionTypes,
    required this.safetyBoundaries,
    required this.escalationThreshold,
    required this.messageDraftStyle,
    required this.routineExamples,
  });

  Map<String, dynamic> toMap() {
    return {
      'personaType': personaType,
      'toneGuidance': toneGuidance,
      'suggestionTypes': suggestionTypes,
      'safetyBoundaries': safetyBoundaries,
      'escalationThreshold': escalationThreshold,
      'messageDraftStyle': messageDraftStyle,
      'routineExamples': routineExamples,
    };
  }

  // ─── Per-Persona Policies ─────────────────────────────────────────

  static const PersonaPolicy child = PersonaPolicy(
    personaType: 'child',
    toneGuidance:
        'Warm, patient, and developmentally aware. Use age-appropriate framing. '
        'Acknowledge that children communicate through behavior, not just words.',
    suggestionTypes: [
      'co-regulation strategies',
      'environmental adjustments',
      'clear and calm communication',
      'sensory considerations',
      'routine reinforcement',
    ],
    safetyBoundaries:
        'Never recommend physical restraint or punishment. '
        'Escalate if physical injury, self-harm in a child, or abuse is mentioned.',
    escalationThreshold: 'medium',
    messageDraftStyle:
        'Short, reassuring phrases the caregiver can say directly to the child. '
        'Simple words, warm tone.',
    routineExamples: [
      'Morning calm routine',
      'School transition routine',
      'Bedtime wind-down routine',
      'Meltdown de-escalation steps',
    ],
  );

  static const PersonaPolicy teenager = PersonaPolicy(
    personaType: 'teenager',
    toneGuidance:
        'Respectful of their autonomy. Avoid talking down or lecturing. '
        'Acknowledge big emotions as valid. Focus on connection over control.',
    suggestionTypes: [
      'open conversation starters',
      'boundary-setting with respect',
      'emotional validation techniques',
      'shared activity ideas',
      'giving space vs. staying present',
    ],
    safetyBoundaries:
        'Escalate promptly for any mention of self-harm, substance use, '
        'risky behaviour, or mental health crisis. Teens may minimize distress.',
    escalationThreshold: 'lower',
    messageDraftStyle:
        'Conversational, non-preachy. Short sentences. '
        'Shows the caregiver is listening, not judging.',
    routineExamples: [
      'Evening check-in ritual',
      'Conflict cool-down steps',
      'Phone-free connection time',
      'Weekend reconnect activity',
    ],
  );

  static const PersonaPolicy baby = PersonaPolicy(
    personaType: 'baby',
    toneGuidance:
        'Practical and reassuring for new or experienced caregivers. '
        'Focus on soothing, routine, and caregiver wellbeing too.',
    suggestionTypes: [
      'soothing techniques',
      'sleep and feeding routines',
      'developmental context',
      'caregiver self-care',
      'environmental adjustments',
    ],
    safetyBoundaries:
        'Escalate immediately for any mention of injury, unsafe sleep, '
        'feeding refusal lasting >24h, or caregiver thoughts of harm.',
    escalationThreshold: 'high-sensitivity',
    messageDraftStyle:
        'Gentle reminders for the caregiver, not messages to the baby. '
        'Warm, short, non-judgmental.',
    routineExamples: [
      'Bedtime soothing routine',
      'Feeding and burp routine',
      'Daytime nap wind-down',
      'Tummy time activity',
    ],
  );

  static const PersonaPolicy parent = PersonaPolicy(
    personaType: 'parent',
    toneGuidance:
        'Compassionate toward caregivers supporting aging or unwell parents. '
        'Honour the parent\'s dignity and autonomy. Acknowledge caregiver fatigue.',
    suggestionTypes: [
      'communication with aging parent',
      'daily care coordination',
      'dignity-preserving approaches',
      'medical and safety planning',
      'caregiver respite and boundaries',
    ],
    safetyBoundaries:
        'Escalate for fall risk, medication non-compliance, cognitive changes, '
        'signs of abuse or neglect, or caregiver crisis.',
    escalationThreshold: 'medium',
    messageDraftStyle:
        'Respectful and adult. Acknowledges the parent\'s experience and feelings. '
        'Not infantilizing.',
    routineExamples: [
      'Morning medication routine',
      'Daily check-in call',
      'Weekly care coordination meeting',
      'Evening wind-down and safety check',
    ],
  );

  static const PersonaPolicy partner = PersonaPolicy(
    personaType: 'partner',
    toneGuidance:
        'Non-judgmental, balanced. Avoids taking sides. '
        'Encourages mutual understanding and honest communication.',
    suggestionTypes: [
      'active listening approaches',
      'repair conversation starters',
      'stress co-regulation',
      'reconnection activities',
      'needs and boundaries clarification',
    ],
    safetyBoundaries:
        'Escalate if any form of abuse, coercive control, or threats are mentioned. '
        'Never suggest staying in an unsafe relationship.',
    escalationThreshold: 'medium',
    messageDraftStyle:
        'Honest, vulnerable, and open. '
        'Phrase as sharing feelings rather than accusations.',
    routineExamples: [
      'Daily 10-minute check-in',
      'Weekly relationship review',
      'Conflict cool-down ritual',
      'Shared evening routine',
    ],
  );

  static const PersonaPolicy sibling = PersonaPolicy(
    personaType: 'sibling',
    toneGuidance:
        'Acknowledge long shared history. '
        'Neutral about sibling dynamics, sensitive to complex family systems.',
    suggestionTypes: [
      'conflict resolution steps',
      'rebuilding connection approaches',
      'shared responsibility strategies',
      'setting clear expectations',
      'processing old resentments',
    ],
    safetyBoundaries:
        'Escalate if domestic violence, financial exploitation, or elder abuse is mentioned.',
    escalationThreshold: 'medium',
    messageDraftStyle:
        'Direct but warm. Acknowledges shared history. '
        'Shows willingness to reconnect.',
    routineExamples: [
      'Regular catch-up call',
      'Family care coordination check-in',
      'Shared family tradition planning',
    ],
  );

  static const PersonaPolicy friend = PersonaPolicy(
    personaType: 'friend',
    toneGuidance:
        'For family members or close friends being supported. '
        'Focus on presence, practical help, and not overstepping.',
    suggestionTypes: [
      'supportive presence strategies',
      'practical help offers',
      'active listening techniques',
      'knowing when to refer professionals',
      'setting healthy support boundaries',
    ],
    safetyBoundaries:
        'Escalate if the person being supported shows crisis signs. '
        'Remind caregiver of their own limits.',
    escalationThreshold: 'medium',
    messageDraftStyle:
        'Warm, present, and supportive without being overwhelming. '
        'Offers help concretely.',
    routineExamples: [
      'Weekly check-in call or visit',
      'Practical help coordination',
      'Shared calming activity',
    ],
  );

  static const PersonaPolicy pet = PersonaPolicy(
    personaType: 'pet',
    toneGuidance:
        'Practical and kind. Focus on pet behaviour, routine, and caregiver stress. '
        'Treats the pet\'s wellbeing seriously without anthropomorphizing.',
    suggestionTypes: [
      'behaviour management approaches',
      'routine reinforcement',
      'environmental enrichment',
      'veterinary guidance suggestions',
      'caregiver patience strategies',
    ],
    safetyBoundaries:
        'Escalate for any mention of pet abuse, severe neglect, or injury. '
        'Recommend vet immediately for health concerns.',
    escalationThreshold: 'medium',
    messageDraftStyle:
        'Not applicable — messages are for the caregiver\'s own reflection, '
        'not to the pet.',
    routineExamples: [
      'Morning feeding and exercise routine',
      'Anxiety management steps',
      'Training reinforcement routine',
      'Evening calming routine',
    ],
  );

  static const PersonaPolicy myself = PersonaPolicy(
    personaType: 'myself',
    toneGuidance:
        'Compassionate self-reflection. No judgment. '
        'Focus on progress, rest, and small sustainable steps.',
    suggestionTypes: [
      'self-compassion practices',
      'stress management techniques',
      'rest and recovery',
      'goal-setting for wellbeing',
      'professional support recommendations',
    ],
    safetyBoundaries:
        'Escalate immediately for any mention of self-harm, suicidal ideation, '
        'or crisis. Provide crisis resources without delay.',
    escalationThreshold: 'highest',
    messageDraftStyle:
        'Internal affirmations and reminders. Kind, non-critical. '
        'Encourages rather than prescribes.',
    routineExamples: [
      'Morning grounding routine',
      'Daily rest and reset',
      'Weekly self-check-in',
      'Evening wind-down routine',
    ],
  );

  // ─── Factory ──────────────────────────────────────────────────────

  static PersonaPolicy forType(String typeName) {
    switch (typeName.toLowerCase()) {
      case 'child':
        return child;
      case 'teenager':
        return teenager;
      case 'baby':
        return baby;
      case 'parent':
        return parent;
      case 'partner':
        return partner;
      case 'sibling':
        return sibling;
      case 'friend':
        return friend;
      case 'pet':
        return pet;
      case 'myself':
        return myself;
      default:
        return friend; // sensible generic fallback
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../services/firestore_service.dart';

const _kSafetyPreamble = '''
SAFETY RULES (always apply):
- You are a supportive guide, NOT a therapist, doctor, or crisis counselor.
- Never diagnose medical or psychological conditions.
- If the situation involves imminent risk of harm, encourage contacting emergency services or 988 — do not give clinical advice.
''';

/// Builds the same narrative shape as the `summarizePatterns` Cloud Function prompt
/// (incidents + check-in summary; plans are fetched for parity but not injected).
String buildLocalWeeklySummarizePrompt(WeeklySummarizeSnapshot snap) {
  final incidents = snap.incidents;
  final checkins = snap.checkins;

  final incidentText = incidents
      .take(10)
      .map((i) {
        final title = i['title'] as String? ?? '';
        final cat = i['category'] as String? ?? 'unknown';
        final inten = i['intensity'] as int? ?? 3;
        return '- $title ($cat, intensity: $inten/5)';
      })
      .join('\n');

  final incidentBlock =
      incidentText.isEmpty ? 'No recent incidents logged.' : incidentText;

  final checkinSummary = checkins.isEmpty
      ? 'No check-ins logged.'
      : '${checkins.where((c) => c['didThisHelp'] == true).length} of ${checkins.length} check-ins reported improvement';

  return '''
$_kSafetyPreamble

You are Crucue, analyzing a caregiver's week to provide gentle insights.

RECENT INCIDENTS (past 7 days):
$incidentBlock

CHECK-IN SUMMARY: $checkinSummary

Provide a brief, encouraging weekly summary. Return raw JSON only (no markdown):
{
  "summary": "2-3 warm sentences acknowledging effort and noting patterns",
  "patterns": ["pattern 1", "pattern 2"],
  "whatWorked": ["what worked 1", "what worked 2"],
  "suggestions": ["suggestion 1", "suggestion 2", "suggestion 3"]
}

Rules:
- summary: acknowledge effort first, then patterns
- patterns: observed recurring themes (max 3)
- whatWorked: positive moments or successful strategies (max 3)
- suggestions: gentle, practical recommendations for the coming week (max 3)
- Be encouraging, never judgmental
'''.trim();
}

Map<String, dynamic> _fallbackInsight() => {
      'summary':
          "Keep going — you're learning what works best for your family.",
      'patterns': <String>[],
      'whatWorked': <String>[],
      'suggestions': ['Continue logging daily moments to build insights.'],
    };

Map<String, dynamic> _parseInsightJson(String raw) {
  var text = raw.trim();
  text = text.replaceFirst(RegExp(r'^```json\s*'), '');
  text = text.replaceFirst(RegExp(r'^```\s*'), '');
  text = text.replaceFirst(RegExp(r'\s*```\s*$'), '');
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, dynamic>) return _fallbackInsight();
  final summary = decoded['summary']?.toString().trim();
  return {
    'summary': summary != null && summary.isNotEmpty
        ? summary
        : "Keep going — you're learning what works best for your family.",
    'patterns': _stringList(decoded['patterns']),
    'whatWorked': _stringList(decoded['whatWorked']),
    'suggestions': _stringList(decoded['suggestions']),
  };
}

List<String> _stringList(dynamic v) {
  if (v is! List) return [];
  return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
}

/// Runs Gemma on-device for weekly insight JSON (Gemma 4 E2B-class weights).
Future<Map<String, dynamic>> summarizeWeeklyWithFlutterGemma(
  WeeklySummarizeSnapshot snap,
) async {
  if (!FlutterGemma.hasActiveModel()) {
    throw StateError('No active flutter_gemma inference model');
  }

  final prompt = buildLocalWeeklySummarizePrompt(snap);
  final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
  InferenceModelSession? session;
  try {
    session = await model.createSession(temperature: 0.6, topK: 40);
    await session.addQueryChunk(Message.text(text: prompt, isUser: true));
    final text = await session.getResponse();
    if (text.trim().isEmpty) return _fallbackInsight();
    try {
      return _parseInsightJson(text);
    } catch (e, st) {
      debugPrint('gemma_local_summarizer: JSON parse failed: $e');
      debugPrint('$st');
      return _fallbackInsight();
    }
  } finally {
    await session?.close();
    await model.close();
  }
}

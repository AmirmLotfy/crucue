import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_engine_registry.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/models/insight.dart';

class InsightsRepository {
  InsightsRepository(this._ref);

  final Ref _ref;

  Stream<List<Insight>> watchInsights(String profileId) =>
      FirestoreService.watchInsights(profileId);

  Future<Insight> generateAndSaveInsight(String profileId) async {
    final data = await _ref.read(aiEngineProvider).summarizePatterns(
          profileId: profileId,
          weekStart: _lastMonday(),
        );
    final insight = Insight(
      id: '',
      profileId: profileId,
      weekStart: _lastMonday(),
      summary: data['summary'] as String? ?? '',
      patterns: _toStringList(data['patterns']),
      whatWorked: _toStringList(data['whatWorked']),
      suggestions: _toStringList(data['suggestions']),
      createdAt: DateTime.now(),
    );
    final id = await FirestoreService.saveInsight(profileId, insight);
    return Insight(
      id: id,
      profileId: insight.profileId,
      weekStart: insight.weekStart,
      summary: insight.summary,
      patterns: insight.patterns,
      whatWorked: insight.whatWorked,
      suggestions: insight.suggestions,
      createdAt: insight.createdAt,
    );
  }

  static DateTime _lastMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref);
});

final insightsProvider =
    StreamProvider.family<List<Insight>, String>((ref, profileId) {
  return ref.watch(insightsRepositoryProvider).watchInsights(profileId);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_back.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/theme.dart';
import '../../../shared/models/insight.dart';
import '../data/insights_repository.dart';

class WeeklyInsightsScreen extends ConsumerStatefulWidget {
  final String profileId;
  final String profileName;

  const WeeklyInsightsScreen({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  ConsumerState<WeeklyInsightsScreen> createState() =>
      _WeeklyInsightsScreenState();
}

class _WeeklyInsightsScreenState extends ConsumerState<WeeklyInsightsScreen> {
  bool _isGenerating = false;

  Future<void> _generateInsight() async {
    setState(() => _isGenerating = true);
    try {
      await ref
          .read(insightsRepositoryProvider)
          .generateAndSaveInsight(widget.profileId);
      showMessage('Weekly insights updated!', type: MessageType.success);
    } catch (e) {
      showMessage('Could not generate insights. Please try again.');
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(insightsProvider(widget.profileId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const AppBack(),
        title: Text(
          '${widget.profileName} — Insights',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: _isGenerating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Generate this week\'s insights',
            onPressed: _isGenerating ? null : _generateInsight,
          ),
        ],
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('Could not load insights.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14.sp)),
        ),
        data: (insights) {
          if (insights.isEmpty) {
            return _EmptyInsights(onGenerate: _generateInsight,
                isGenerating: _isGenerating);
          }
          return ListView(
            padding: EdgeInsets.all(20.r),
            children: [
              _GenerateCard(
                onGenerate: _generateInsight,
                isGenerating: _isGenerating,
              ),
              SizedBox(height: 20.h),
              ...insights.map((i) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _InsightCard(insight: i),
                  )),
              SizedBox(height: 24.h),
            ],
          );
        },
      ),
    );
  }
}

// ─── Generate Card ────────────────────────────────────────────────────────────

class _GenerateCard extends StatelessWidget {
  final VoidCallback onGenerate;
  final bool isGenerating;

  const _GenerateCard({required this.onGenerate, required this.isGenerating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate this week\'s insights',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'AI will summarize your logs, patterns, and what\'s working.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: isGenerating ? null : onGenerate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 10.h),
              elevation: 0,
            ),
            child: isGenerating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : Text(
                    'Generate',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Insight Card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatefulWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    final isThisWeek = _isThisWeek(insight.weekStart);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isThisWeek
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
          width: isThisWeek ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isThisWeek
                            ? AppTheme.primary.withValues(alpha: 0.10)
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        isThisWeek
                            ? 'This week'
                            : 'Week of ${DateFormat('MMM d').format(insight.weekStart)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isThisWeek
                              ? AppTheme.primary
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _expanded = !_expanded),
                      child: Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Theme.of(context).hintColor,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  insight.summary,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (insight.whatWorked.isNotEmpty) ...[
                    _InsightSection(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: CrucueTokens.success,
                      title: 'What worked',
                      items: insight.whatWorked,
                    ),
                    SizedBox(height: 14.h),
                  ],
                  if (insight.patterns.isNotEmpty) ...[
                    _InsightSection(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppTheme.primary,
                      title: 'Patterns noticed',
                      items: insight.patterns,
                    ),
                    SizedBox(height: 14.h),
                  ],
                  if (insight.suggestions.isNotEmpty) ...[
                    _InsightSection(
                      icon: Icons.lightbulb_outline_rounded,
                      iconColor: CrucueTokens.warning,
                      title: 'For next week',
                      items: insight.suggestions,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isThisWeek(DateTime weekStart) {
    final now = DateTime.now();
    final thisMonday =
        now.subtract(Duration(days: now.weekday - 1));
    final monday = DateTime(
        thisMonday.year, thisMonday.month, thisMonday.day);
    final ws = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return ws.isAtSameMomentAs(monday) ||
        (ws.isBefore(now) &&
            ws.isAfter(monday.subtract(const Duration(days: 1))));
  }
}

class _InsightSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _InsightSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: iconColor),
            SizedBox(width: 6.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(left: 20.w, bottom: 5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6.h),
                    width: 4.h,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyInsights extends StatelessWidget {
  final VoidCallback onGenerate;
  final bool isGenerating;

  const _EmptyInsights({
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 52.sp,
            color: AppTheme.primary.withValues(alpha: 0.35),
          ),
          SizedBox(height: 20.h),
          Text(
            'Insights build with time',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: AppTheme.fontFamily2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            'Log a few challenges this week and tap Generate to see patterns, what worked, and helpful suggestions.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.h),
          FilledButton.icon(
            icon: isGenerating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            onPressed: isGenerating ? null : onGenerate,
            label: Text(isGenerating ? 'Generating…' : 'Generate Insights'),
          ),
        ],
      ),
    );
  }
}

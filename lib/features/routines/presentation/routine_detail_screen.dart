import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_back.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../shared/models/routine.dart';

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final String profileId;
  final Routine routine;

  const RoutineDetailScreen({
    super.key,
    required this.profileId,
    required this.routine,
  });

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  late List<bool> _stepsCompleted;
  bool _isStarted = false;
  bool _isMarkingDone = false;

  @override
  void initState() {
    super.initState();
    _stepsCompleted =
        List.filled(widget.routine.steps.length, false);
  }

  Future<void> _markComplete() async {
    setState(() => _isMarkingDone = true);
    try {
      await FirestoreService.markRoutineUsed(
          widget.profileId, widget.routine.id);
      showMessage('Routine completed! Great work.', type: MessageType.success);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showMessage('Could not save completion. Please try again.');
    }
    if (mounted) setState(() => _isMarkingDone = false);
  }

  Future<void> _archiveRoutine() async {
    try {
      await FirestoreService.updateRoutine(
          widget.profileId, widget.routine.id, {'isActive': false});
      showMessage('Routine archived.', type: MessageType.success);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMessage('Could not archive routine.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.routine;
    final allDone = _stepsCompleted.every((c) => c);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const AppBack(),
        title: Text(
          routine.title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              if (action == _MenuAction.archive) _archiveRoutine();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _MenuAction.archive,
                child: Text('Archive routine'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Metadata row ─────────────────────────────────────
            _MetaRow(routine: routine),
            SizedBox(height: 20.h),

            // ─── Description ──────────────────────────────────────
            if (routine.description != null &&
                routine.description!.isNotEmpty) ...[
              Text(
                routine.description!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ─── Steps ────────────────────────────────────────────
            if (routine.steps.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Steps',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (!_isStarted)
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      onPressed: () => setState(() => _isStarted = true),
                      label: const Text('Start'),
                      style: FilledButton.styleFrom(
                        fixedSize: Size.fromHeight(34.h),
                        textStyle: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10.h),
              ...List.generate(routine.steps.length, (i) {
                final done = _stepsCompleted[i];
                return GestureDetector(
                  onTap: _isStarted
                      ? () =>
                          setState(() => _stepsCompleted[i] = !_stepsCompleted[i])
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: done
                          ? CrucueTokens.successSubtle
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: done
                            ? CrucueTokens.success
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28.h,
                          height: 28.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: done
                                ? CrucueTokens.success
                                : Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: done
                                  ? CrucueTokens.success
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: done
                              ? Icon(Icons.check_rounded,
                                  size: 14.sp, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            routine.steps[i],
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: done
                                  ? Theme.of(context).hintColor
                                  : Theme.of(context).colorScheme.onSurface,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            SizedBox(height: 24.h),

            // ─── Completion stats ─────────────────────────────────
            if (routine.completionCount > 0)
              _StatsRow(routine: routine),

            SizedBox(height: 32.h),

            // ─── Mark complete ────────────────────────────────────
            if (_isStarted) ...[
              if (!allDone) ...[
                Text(
                  '${_stepsCompleted.where((c) => c).length} of ${routine.steps.length} steps done',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
              ],
              FilledButton.icon(
                icon: _isMarkingDone
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded,
                        size: 18),
                onPressed: _isMarkingDone ? null : _markComplete,
                label: const Text('Mark as Complete'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Routine routine;
  const _MetaRow({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _Chip(
          icon: Icons.repeat_rounded,
          label: routine.frequency.label,
          color: AppTheme.primary,
        ),
        if (routine.steps.isNotEmpty)
          _Chip(
            icon: Icons.format_list_numbered_rounded,
            label: '${routine.steps.length} steps',
            color: CrucueTokens.info,
          ),
        if (routine.completionCount > 0)
          _Chip(
            icon: Icons.check_circle_rounded,
            label: '${routine.completionCount}× completed',
            color: CrucueTokens.success,
          ),
        if (routine.tags.isNotEmpty)
          ...routine.tags.map((t) => _Chip(
                icon: Icons.label_outline_rounded,
                label: t,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              )),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Routine routine;
  const _StatsRow({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '${routine.completionCount}',
            label: 'Completions',
          ),
          Container(width: 1, height: 32.h, color: Theme.of(context).dividerColor),
          _StatItem(
            value: routine.lastUsedAt != null
                ? DateFormat('MMM d').format(routine.lastUsedAt!)
                : '—',
            label: 'Last used',
          ),
          Container(width: 1, height: 32.h, color: Theme.of(context).dividerColor),
          _StatItem(
            value: routine.frequency.label,
            label: 'Frequency',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}

enum _MenuAction { archive }

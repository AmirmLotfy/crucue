import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_back.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/theme.dart';
import '../../../shared/models/routine.dart';
import '../data/routines_repository.dart';
import 'routine_detail_screen.dart';
import 'save_as_routine_screen.dart';

class RoutinesListScreen extends ConsumerWidget {
  final String profileId;
  final String profileName;

  const RoutinesListScreen({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider(profileId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const AppBack(),
        title: Text(
          '$profileName\'s Routines',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => navigateTo(
              SaveAsRoutineScreen(profileId: profileId),
            ),
          ),
        ],
      ),
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('Could not load routines.',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14.sp)),
        ),
        data: (routines) {
          if (routines.isEmpty) {
            return _EmptyRoutines(profileId: profileId);
          }
          final active = routines.where((r) => r.isActive).toList();
          final archived = routines.where((r) => !r.isActive).toList();
          return ListView(
            padding: EdgeInsets.all(20.r),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(title: 'Active routines', count: active.length),
                SizedBox(height: 10.h),
                ...active.map((r) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _RoutineCard(
                          routine: r, profileId: profileId),
                    )),
              ],
              if (archived.isNotEmpty) ...[
                SizedBox(height: 16.h),
                _SectionHeader(
                    title: 'Archived', count: archived.length),
                SizedBox(height: 10.h),
                ...archived.map((r) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _RoutineCard(
                          routine: r, profileId: profileId),
                    )),
              ],
              SizedBox(height: 24.h),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            navigateTo(SaveAsRoutineScreen(profileId: profileId)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Routine'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  final Routine routine;
  final String profileId;

  const _RoutineCard({required this.routine, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          navigateTo(RoutineDetailScreen(profileId: profileId, routine: routine)),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: routine.isActive
                ? AppTheme.primary.withValues(alpha: 0.2)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.h,
              height: 44.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: routine.isActive
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat_rounded,
                color: routine.isActive
                    ? AppTheme.primary
                    : Theme.of(context).hintColor,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          routine.frequency.label,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (routine.completionCount > 0) ...[
                        SizedBox(width: 6.w),
                        Icon(Icons.check_circle_outline_rounded,
                            size: 12.sp,
                            color: CrucueTokens.success),
                        SizedBox(width: 2.w),
                        Text(
                          '${routine.completionCount}×',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: CrucueTokens.success,
                          ),
                        ),
                      ],
                      if (routine.lastUsedAt != null) ...[
                        SizedBox(width: 6.w),
                        Text(
                          'Last: ${DateFormat('MMM d').format(routine.lastUsedAt!)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18.sp, color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  final String profileId;

  const _EmptyRoutines({required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.repeat_rounded,
              size: 52.sp,
              color: AppTheme.primary.withValues(alpha: 0.35)),
          SizedBox(height: 20.h),
          Text(
            'No routines yet',
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
            'After using a support plan, you can save the steps as a reusable routine — like a bedtime calm-down or morning check-in.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.h),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                navigateTo(SaveAsRoutineScreen(profileId: profileId)),
            label: const Text('Create a Routine'),
          ),
        ],
      ),
    );
  }
}

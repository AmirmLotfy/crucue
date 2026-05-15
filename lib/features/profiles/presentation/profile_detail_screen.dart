import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/logic/helper_methods.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../features/incidents/presentation/add_incident_screen.dart';
import '../../../features/insights/presentation/weekly_insights_screen.dart';
import '../../../features/routines/presentation/routines_list_screen.dart';
import '../../../shared/models/care_profile.dart';
import '../../../shared/models/incident.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/support_plan.dart';
import '../../../views/chat/view.dart';
import '../../../views/select_persona.dart';
import '../../plans/presentation/checkin_screen.dart';
import '../data/profiles_repository.dart';

/// Maps a [CareRelationship] to the closest [PersonaType] for AI policy selection.
PersonaType _relationshipToPersona(CareRelationship r) {
  switch (r) {
    case CareRelationship.child:
      return PersonaType.child;
    case CareRelationship.parent:
      return PersonaType.parent;
    case CareRelationship.partner:
      return PersonaType.partner;
    case CareRelationship.sibling:
      return PersonaType.sibling;
    case CareRelationship.familyMember:
      return PersonaType.friend;
  }
}

class ProfileDetailScreen extends ConsumerWidget {
  final String profileId;

  const ProfileDetailScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesStreamProvider);

    final profile = profilesAsync.valueOrNull?.firstWhere(
      (p) => p.id == profileId,
      orElse: () => CareProfile(
        id: profileId,
        name: '',
        relationship: CareRelationship.child,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (profile == null || profile.name.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _ProfileAppBar(profile: profile),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuickActionsRow(profile: profile),
                SizedBox(height: 4.h),
                _RecentIncidentsSection(
                  profileId: profileId,
                  profileName: profile.name,
                  personaType: _relationshipToPersona(profile.relationship),
                ),
                _RecentPlansSection(profileId: profileId),
                _ActiveRoutinesSection(
                  profileId: profileId,
                  profileName: profile.name,
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  final CareProfile profile;

  const _ProfileAppBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180.h,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                profile.relationship.profileColor.withValues(alpha: 0.25),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 56.h, 20.w, 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 64.h,
                    height: 64.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          profile.relationship.profileColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: profile.relationship.profileColor
                            .withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      profile.relationship.materialIcon,
                      color: AppTheme.primary,
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: AppTheme.fontFamily2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          profile.relationship.label +
                              (profile.ageGroup != null
                                  ? ' · ${profile.ageGroup}'
                                  : ''),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (profile.supportFocus != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            profile.supportFocus!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final CareProfile profile;

  const _QuickActionsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      child: Row(
        children: [
          _QuickAction(
            icon: Icons.add_circle_outline_rounded,
            label: 'Log\nChallenge',
            color: AppTheme.primary,
            onTap: () => navigateTo(
              AddIncidentScreen(
                profileId: profile.id,
                profileName: profile.name,
                personaType: _relationshipToPersona(profile.relationship),
              ),
            ),
          ),
          _QuickAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat with\nCrucue',
            color: CrucueTokens.info,
            onTap: () => navigateTo(
              ChatView(
                profileId: profile.id,
                profileName: profile.name,
              ),
            ),
          ),
          _QuickAction(
            icon: Icons.repeat_rounded,
            label: 'My\nRoutines',
            color: CrucueTokens.info,
            onTap: () => navigateTo(RoutinesListScreen(
              profileId: profile.id,
              profileName: profile.name,
            )),
          ),
          _QuickAction(
            icon: Icons.bar_chart_rounded,
            label: 'Weekly\nInsights',
            color: CrucueTokens.warning,
            onTap: () => navigateTo(
              WeeklyInsightsScreen(
                profileId: profile.id,
                profileName: profile.name,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48.h,
              height: 48.h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Incidents ─────────────────────────────────────────────────────────

class _RecentIncidentsSection extends StatelessWidget {
  final String profileId;
  final String profileName;
  final PersonaType personaType;

  const _RecentIncidentsSection({
    required this.profileId,
    required this.profileName,
    required this.personaType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Incident>>(
      stream: FirestoreService.watchRecentIncidents(profileId, limit: 3),
      builder: (context, snap) {
        final incidents = snap.data ?? [];
        return _SectionWrapper(
          title: 'Recent Moments',
          actionLabel: incidents.isEmpty ? null : 'Log new',
          onAction: () => navigateTo(AddIncidentScreen(
            profileId: profileId,
            profileName: profileName,
            personaType: personaType,
          )),
          emptyTitle: 'Nothing logged yet',
          emptyBody: 'Log a challenge to get your first support plan.',
          isEmpty: incidents.isEmpty,
          children: incidents
              .map((i) => _IncidentTile(
                    incident: i,
                    profileId: profileId,
                    profileName: profileName,
                    personaType: personaType,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final Incident incident;
  final String profileId;
  final String profileName;
  final PersonaType personaType;

  const _IncidentTile({
    required this.incident,
    required this.profileId,
    required this.profileName,
    required this.personaType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        navigateTo(AddIncidentScreen(
          profileId: profileId,
          profileName: profileName,
          personaType: personaType,
          existingIncidentId: incident.id,
        ));
      },
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 8.w,
              height: 8.w,
              margin: EdgeInsets.only(right: 12.w, top: 6.h),
              decoration: BoxDecoration(
                color: _intensityColor(incident.intensity),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    DateFormat('MMM d').format(incident.createdAt),
                    style:
                        TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: incident.category.chipColor(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                incident.category.label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: incident.category.chipColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _intensityColor(int intensity) {
    if (intensity <= 2) return CrucueTokens.success;
    if (intensity <= 3) return CrucueTokens.warning;
    return AppTheme.warmCoral;
  }
}

// ─── Recent Plans ─────────────────────────────────────────────────────────────

class _RecentPlansSection extends StatelessWidget {
  final String profileId;

  const _RecentPlansSection({required this.profileId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SupportPlan>>(
      stream: FirestoreService.watchRecentPlans(profileId, limit: 3),
      builder: (context, snap) {
        final plans = snap.data ?? [];
        return _SectionWrapper(
          title: 'Support Plans',
          actionLabel: null,
          onAction: null,
          emptyTitle: 'No plans saved yet',
          emptyBody: 'Log a challenge to generate your first support plan.',
          isEmpty: plans.isEmpty,
          children:
              plans.map((p) => _PlanTile(plan: p, profileId: profileId)).toList(),
        );
      },
    );
  }
}

class _PlanTile extends StatelessWidget {
  final SupportPlan plan;
  final String profileId;

  const _PlanTile({required this.plan, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to check-in for this plan
        navigateTo(CheckInScreen(profileId: profileId, plan: plan));
      },
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 14.sp, color: AppTheme.primary),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    plan.summary.length > 80
                        ? '${plan.summary.substring(0, 80)}…'
                        : plan.summary,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, y').format(plan.createdAt),
                  style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
                ),
                Text(
                  'Reflect →',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Routines ──────────────────────────────────────────────────────────

class _ActiveRoutinesSection extends StatelessWidget {
  final String profileId;
  final String profileName;

  const _ActiveRoutinesSection({
    required this.profileId,
    required this.profileName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Routine>>(
      stream: FirestoreService.watchRoutines(profileId, activeOnly: true),
      builder: (context, snap) {
        final routines = snap.data ?? [];
        if (routines.isEmpty) return const SizedBox.shrink();
        return _SectionWrapper(
          title: 'Saved Routines',
          actionLabel: 'See all',
          onAction: () => navigateTo(RoutinesListScreen(
            profileId: profileId,
            profileName: profileName,
          )),
          isEmpty: false,
          emptyTitle: '',
          emptyBody: '',
          children: routines
              .take(3)
              .map((r) => _RoutineTile(routine: r, profileId: profileId))
              .toList(),
        );
      },
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final Routine routine;
  final String profileId;

  const _RoutineTile({required this.routine, required this.profileId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.decor.planReflect),
      ),
      child: Row(
        children: [
          Container(
            width: 36.h,
            height: 36.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.decor.planReflect,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.repeat_rounded,
                size: 18.sp, color: AppTheme.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (routine.steps.isNotEmpty)
                  Text(
                    '${routine.steps.length} steps',
                    style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
                  ),
              ],
            ),
          ),
          Text(
            routine.frequency.label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Wrapper ──────────────────────────────────────────────────────────

class _SectionWrapper extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isEmpty;
  final String emptyTitle;
  final String emptyBody;
  final List<Widget> children;

  const _SectionWrapper({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.isEmpty,
    required this.emptyTitle,
    required this.emptyBody,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          if (isEmpty)
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emptyTitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    emptyBody,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: children
                  .map((c) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: c,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Extensions ───────────────────────────────────────────────────────────────

extension _CareRelationshipStyle on CareRelationship {
  Color get profileColor {
    switch (this) {
      case CareRelationship.child:
        return CrucueTokens.personaChild;
      case CareRelationship.parent:
        return CrucueTokens.personaParent;
      case CareRelationship.partner:
        return CrucueTokens.personaPartner;
      case CareRelationship.sibling:
        return CrucueTokens.personaSibling;
      case CareRelationship.familyMember:
        return CrucueTokens.personaFriend;
    }
  }

  IconData get materialIcon {
    switch (this) {
      case CareRelationship.child:
        return Icons.child_care_rounded;
      case CareRelationship.parent:
        return Icons.elderly_rounded;
      case CareRelationship.partner:
        return Icons.favorite_rounded;
      case CareRelationship.sibling:
        return Icons.group_rounded;
      case CareRelationship.familyMember:
        return Icons.people_rounded;
    }
  }
}

extension _IncidentCategoryStyle on IncidentCategory {
  Color chipColor(BuildContext context) {
    switch (this) {
      case IncidentCategory.behavior:
        return CrucueTokens.error;
      case IncidentCategory.communication:
        return CrucueTokens.info;
      case IncidentCategory.emotion:
        return const Color(0xff7C3AED);
      case IncidentCategory.health:
        return CrucueTokens.success;
      case IncidentCategory.routine:
        return CrucueTokens.warning;
      case IncidentCategory.safety:
        return AppTheme.warmCoral;
      case IncidentCategory.other:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}

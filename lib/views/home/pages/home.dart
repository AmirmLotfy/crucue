import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/branding/crucue_brand_logo.dart';
import '../../../core/logic/cache_helper.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../features/profiles/data/profiles_repository.dart';
import '../../../features/profiles/presentation/create_profile_screen.dart';
import '../../../features/profiles/presentation/profile_detail_screen.dart';
import '../../../shared/models/care_profile.dart';
import '../../../shared/models/incident.dart';
import '../../select_persona.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _HomeAppBar(),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Something went wrong. Pull down to retry.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14.sp),
          ),
        ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return _NoProfilesState();
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
            children: [
              // ─── Care Profiles section ─────────────────────────
              _SectionHeader(
                title: 'Your Care Profiles',
                actionLabel: '+ Add',
                onAction: () => navigateTo(const CreateProfileScreen()),
              ),
              SizedBox(height: 10.h),
              ...profiles.map(
                (p) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _ProfileCard(profile: p),
                ),
              ),

              SizedBox(height: 20.h),

              // ─── Recent activity ───────────────────────────────
              if (profiles.isNotEmpty) ...[
                _SectionHeader(title: 'Recent Activity'),
                SizedBox(height: 10.h),
                _RecentActivityFeed(profiles: profiles),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    final firstName = CacheHelper.firstName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      toolbarHeight: 64.h,
      titleSpacing: 12.w,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrucueBrandLogo(
            forDarkBackground: isDark,
            maxHeight: 40.h,
            maxWidth: 100.w,
            alignment: Alignment.centerLeft,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  firstName.isNotEmpty ? 'Hello, $firstName 👋' : 'Hello 👋',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'How can Crucue help today?',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final CareProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateTo(ProfileDetailScreen(profileId: profile.id)),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _relationshipColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 48.h,
              height: 48.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _relationshipColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _relationshipIcon,
                color: AppTheme.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    profile.relationship.label +
                        (profile.ageGroup != null
                            ? ' · ${profile.ageGroup}'
                            : ''),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (profile.supportFocus != null) ...[
                    SizedBox(height: 3.h),
                    Text(
                      profile.supportFocus!,
                      style: TextStyle(
                        fontSize: 11.sp,
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
            SizedBox(width: 8.w),
            // Quick action: log challenge
            GestureDetector(
              onTap: () {
                // Navigate to SelectPersonaView to start a new care session
                navigateTo(SelectPersonaView());
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Log',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _relationshipColor {
    switch (profile.relationship) {
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

  IconData get _relationshipIcon {
    switch (profile.relationship) {
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

// ─── Recent Activity Feed ─────────────────────────────────────────────────────

class _RecentActivityFeed extends StatelessWidget {
  final List<CareProfile> profiles;

  const _RecentActivityFeed({required this.profiles});

  @override
  Widget build(BuildContext context) {
    // Show recent incidents from the first 2 profiles
    final profilesToShow = profiles.take(2).toList();
    return Column(
      children: profilesToShow
          .map((p) => _ProfileRecentIncidents(profile: p))
          .toList(),
    );
  }
}

class _ProfileRecentIncidents extends StatelessWidget {
  final CareProfile profile;

  const _ProfileRecentIncidents({required this.profile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Incident>>(
      stream: FirestoreService.watchRecentIncidents(profile.id, limit: 2),
      builder: (context, snap) {
        final incidents = snap.data ?? [];
        if (incidents.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: incidents.map((incident) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _ActivityTile(
                incident: incident,
                profileName: profile.name,
                profileId: profile.id,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Incident incident;
  final String profileName;
  final String profileId;

  const _ActivityTile({
    required this.incident,
    required this.profileName,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          navigateTo(ProfileDetailScreen(profileId: profileId)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36.h,
              height: 36.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notes_rounded,
                  size: 16.sp, color: AppTheme.primary),
            ),
            SizedBox(width: 12.w),
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
                    '$profileName · ${DateFormat('MMM d').format(incident.createdAt)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16.sp, color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _NoProfilesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.h,
            height: 80.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.10),
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 40.sp,
              color: AppTheme.primary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Start your first care profile',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: AppTheme.fontFamily2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'Create a profile for someone you care for, log a challenge, and get a personalised support plan.',
            style: TextStyle(
              fontSize: 15.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => navigateTo(const CreateProfileScreen()),
            label: const Text('Create a Care Profile'),
          ),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            icon: const Icon(Icons.explore_rounded),
            onPressed: () => navigateTo(SelectPersonaView()),
            label: const Text('Try the quick flow'),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

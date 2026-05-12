import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/logic/helper_methods.dart';
import '../../../core/observability/analytics_events.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../shared/models/care_profile.dart';
import '../../../views/home/view.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageGroupController = TextEditingController();
  final _supportFocusController = TextEditingController();
  final _whatHelpsController = TextEditingController();
  final _whatToAvoidController = TextEditingController();
  final _healthNotesController = TextEditingController();
  final _commPrefsController = TextEditingController();

  CareRelationship _selectedRelationship = CareRelationship.child;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageGroupController.dispose();
    _supportFocusController.dispose();
    _whatHelpsController.dispose();
    _whatToAvoidController.dispose();
    _healthNotesController.dispose();
    _commPrefsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final profile = CareProfile(
        id: '',
        name: _nameController.text.trim(),
        relationship: _selectedRelationship,
        ageGroup: _ageGroupController.text.trim().isEmpty
            ? null
            : _ageGroupController.text.trim(),
        supportFocus: _supportFocusController.text.trim().isEmpty
            ? null
            : _supportFocusController.text.trim(),
        communicationPreferences: _commPrefsController.text.trim().isEmpty
            ? null
            : _commPrefsController.text.trim(),
        whatHelps: _whatHelpsController.text.trim().isEmpty
            ? null
            : _whatHelpsController.text.trim(),
        whatToAvoid: _whatToAvoidController.text.trim().isEmpty
            ? null
            : _whatToAvoidController.text.trim(),
        healthNotes: _healthNotesController.text.trim().isEmpty
            ? null
            : _healthNotesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await FirestoreService.createProfile(profile);
      CrucueAnalytics.logProfileCreated(relationship: _selectedRelationship.name);
      showMessage('Care profile created!', type: MessageType.success);
      navigateTo(const HomeView(), keepHistory: false);
    } catch (e) {
      showMessage('Could not save profile. Please try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('New Care Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20.r),
          children: [
            _SectionHeader(
                title: 'Who are you supporting?',
                subtitle: 'This helps Crucue personalize your support plans.'),
            SizedBox(height: 16.h),
            _RelationshipSelector(
              selected: _selectedRelationship,
              onChanged: (r) => setState(() => _selectedRelationship = r),
            ),
            SizedBox(height: 24.h),
            _SectionHeader(title: 'Their name'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'First name or nickname',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            SizedBox(height: 20.h),
            _SectionHeader(
                title: 'Age group',
                subtitle: 'Optional — helps tailor the guidance.'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _ageGroupController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Toddler (2-4), Teen (13-17), Senior (65+)',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
            ),
            SizedBox(height: 20.h),
            _SectionHeader(
                title: 'Main support focus',
                subtitle: 'What do you most want to improve?'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _supportFocusController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Managing meltdowns, daily routine, communication',
              ),
            ),
            SizedBox(height: 20.h),
            _SectionHeader(
                title: 'What usually helps',
                subtitle: 'Strategies or things that calm or comfort them.'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _whatHelpsController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Quiet time, a favorite toy, a short walk',
              ),
            ),
            SizedBox(height: 20.h),
            _SectionHeader(
                title: 'What to avoid',
                subtitle: 'Things that tend to make situations harder.'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _whatToAvoidController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Loud voices, sudden changes, being rushed',
              ),
            ),
            SizedBox(height: 20.h),
            _SectionHeader(
                title: 'Communication preferences',
                subtitle: 'How do they communicate best?'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _commPrefsController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Short sentences, visual cues, one-on-one time',
              ),
            ),
            SizedBox(height: 20.h),
            _SectionHeader(
                title: 'Health or context notes',
                subtitle: 'Optional. Any conditions, medications, or context.'),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _healthNotesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'e.g. ADHD, anxiety, takes medication in the morning',
              ),
            ),
            SizedBox(height: 32.h),
            FilledButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Profile'),
            ),
            SizedBox(height: 16.h),
            Text(
              'This profile is private and only visible to you.',
              style: TextStyle(fontSize: 12.sp, color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 2.h),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 12.sp, color: Theme.of(context).hintColor),
          ),
        ],
      ],
    );
  }
}

class _RelationshipSelector extends StatelessWidget {
  final CareRelationship selected;
  final ValueChanged<CareRelationship> onChanged;

  const _RelationshipSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: CareRelationship.values.map((r) {
        final isSelected = r == selected;
        return GestureDetector(
          onTap: () => onChanged(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Theme.of(context).dividerColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  r.materialIcon,
                  size: 16.sp,
                  color: isSelected ? Colors.white : Theme.of(context).hintColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

extension _CareRelationshipIcon on CareRelationship {
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

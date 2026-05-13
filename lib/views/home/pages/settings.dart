import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:crucue/core/design/app_image.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/views/dialogs/logout.dart';
import 'package:crucue/views/settings/help.dart';
import 'package:crucue/views/settings/notifications.dart';
import 'package:crucue/views/settings/privacy.dart';
import 'package:crucue/views/settings/profile.dart';

import '../../../app/providers.dart';
import '../../../core/ai/ai_engine_registry.dart';
import '../../../core/ai/on_device_model_config.dart';
import '../../../core/config/demo_access.dart';
import '../../../core/config/env_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme.dart';
import '../../../shared/models/care_profile.dart';
import '../../dialogs/delete_account.dart';
import '../../legal/privacy_policy_screen.dart';
import '../../legal/terms_screen.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final aiMode = ref.watch(aiModeProvider);
    final showOnDeviceModel = FeatureFlags.onDeviceAiEnabled &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            // ─── Appearance ──────────────────────────────────────
            _SectionHeader(title: 'Appearance'),
            _ThemeSelector(current: themeMode),
            SizedBox(height: 8.h),
            const Divider(),
            SizedBox(height: 16.h),

            // ─── AI ──────────────────────────────────────────────
            _SectionHeader(title: 'AI Engine'),
            _AiModeSelector(current: aiMode),
            SizedBox(height: 8.h),
            if (showOnDeviceModel) ...[
              SizedBox(height: 12.h),
              const _OnDeviceModelSection(),
            ],
            const Divider(),
            SizedBox(height: 16.h),

            // ─── Account ─────────────────────────────────────────
            _SectionHeader(title: 'Account'),
            _Item(
              text: 'Profile',
              image: 'profile.svg',
              onPress: () => navigateTo(const ProfileView()),
            ),
            _Item(
              text: 'Notifications',
              image: 'notification.svg',
              onPress: () => navigateTo(const NotificationsView()),
            ),
            _Item(
              text: 'Data privacy and usage',
              image: 'data_privacy_and_usage.svg',
              onPress: () => navigateTo(const PrivacyView()),
            ),
            _Item(
              text: 'Help and support',
              image: 'help_and_support.svg',
              onPress: () => navigateTo(const HelpView()),
            ),
            _Item(
              text: 'Delete Account',
              image: 'delete_account.svg',
              onPress: () => showDialog(
                context: context,
                builder: (_) => const DeleteAccountDialog(),
              ),
            ),
            _Item(
              text: 'Logout',
              image: 'logout.svg',
              onPress: () => showDialog(
                context: context,
                builder: (_) => const LogoutDialog(),
              ),
            ),

            // ─── Legal ───────────────────────────────────────────────
            _SectionHeader(title: 'Legal'),
            _Item(
              text: 'Privacy Policy',
              image: 'data_privacy_and_usage.svg',
              onPress: () => navigateTo(const PrivacyPolicyScreen()),
            ),
            _Item(
              text: 'Terms of Service',
              image: 'data_privacy_and_usage.svg',
              onPress: () => navigateTo(const TermsScreen()),
            ),

            // ─── Demo profile seed (debug, or release with SHOW_DEMO_SEED) ─
            if (showDemoProfileSeeding) ...[
              _SectionHeader(
                title: kDebugMode ? 'Demo (debug only)' : 'Demo (reviewer build)',
              ),
              const _LoadDemoProfileButton(),
              const Divider(),
              SizedBox(height: 16.h),
            ],

            // ─── App version ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                'Crucue ${EnvConfig.appVersion}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).hintColor,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  final ThemeMode current;
  const _ThemeSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ThemeOption(
              label: 'System default',
              icon: Icons.brightness_auto_rounded,
              selected: current == ThemeMode.system,
              onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            _ThemeOption(
              label: 'Light',
              icon: Icons.light_mode_rounded,
              selected: current == ThemeMode.light,
              onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            _ThemeOption(
              label: 'Dark',
              icon: Icons.dark_mode_rounded,
              selected: current == ThemeMode.dark,
              onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: isLast
              ? BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                )
              : BorderRadius.zero,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: selected ? AppTheme.primary : cs.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.primary : cs.onSurface,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 18.sp, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _AiModeSelector extends ConsumerWidget {
  final AiMode current;
  const _AiModeSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final modes = AiMode.values;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < modes.length; i++) ...[
              _AiModeOption(
                mode: modes[i],
                selected: current == modes[i],
                isLast: i == modes.length - 1,
                onTap: () =>
                    ref.read(aiModeProvider.notifier).setMode(modes[i]),
              ),
              if (i < modes.length - 1)
                Divider(height: 1, color: Theme.of(context).dividerColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiModeOption extends StatelessWidget {
  final AiMode mode;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  const _AiModeOption({
    required this.mode,
    required this.selected,
    required this.isLast,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case AiMode.remote:
        return Icons.cloud_rounded;
      case AiMode.onDevice:
        return Icons.phone_android_rounded;
      case AiMode.auto:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: isLast
              ? BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                )
              : BorderRadius.zero,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _icon,
              size: 20.sp,
              color: selected ? AppTheme.primary : cs.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppTheme.primary : cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    mode.description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Icon(Icons.check_rounded, size: 18.sp, color: AppTheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnDeviceModelSection extends StatefulWidget {
  const _OnDeviceModelSection();

  @override
  State<_OnDeviceModelSection> createState() => _OnDeviceModelSectionState();
}

class _OnDeviceModelSectionState extends State<_OnDeviceModelSection> {
  bool _loading = true;
  bool _installed = false;
  bool _active = false;
  bool _downloading = false;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final installed = await FlutterGemma.isModelInstalled(
        kCrucueOnDeviceDefaultModelFileName,
      );
      if (!mounted) return;
      setState(() {
        _installed = installed;
        _active = FlutterGemma.hasActiveModel();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });
    try {
      await FlutterGemma.installModel(
        modelType: kCrucueOnDeviceModelType,
        fileType: kCrucueOnDeviceModelFileType,
      )
          .fromNetwork(kCrucueOnDeviceGemma4E2bLitertLmUrl)
          .withProgress((p) {
            if (mounted) setState(() => _progress = p);
          })
          .install();
      if (!mounted) return;
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('On-device model ready')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _error = null);
    try {
      await FlutterGemma.uninstallModel(kCrucueOnDeviceDefaultModelFileName);
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gemma 4 on-device (E2B)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Community flutter_gemma plugin + ~2.6 GB download. Used for weekly '
            'insights only — not the same quality tier as cloud Gemma 26B.',
            style: TextStyle(
              fontSize: 11.sp,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_loading) ...[
            SizedBox(height: 12.h),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            SizedBox(height: 10.h),
            Text(
              _active
                  ? 'Model active for weekly insights.'
                  : (_installed
                      ? 'Installed; generating may activate the model on first use.'
                      : 'Not installed.'),
              style: TextStyle(fontSize: 12.sp, color: cs.onSurface),
            ),
            if (_downloading) ...[
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100 : null,
              ),
              SizedBox(height: 4.h),
              Text(
                'Downloading… $_progress%',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _downloading ? null : _download,
                    child: Text(_installed ? 'Re-download / repair' : 'Download'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        (!_installed && !_active) || _downloading ? null : _delete,
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadDemoProfileButton extends StatefulWidget {
  const _LoadDemoProfileButton();

  @override
  State<_LoadDemoProfileButton> createState() => _LoadDemoProfileButtonState();
}

class _LoadDemoProfileButtonState extends State<_LoadDemoProfileButton> {
  bool _loading = false;

  Future<void> _seed() async {
    setState(() => _loading = true);
    try {
      final raw = await rootBundle.loadString('assets/demo/demo_profile.json');
      final map = json.decode(raw) as Map<String, dynamic>;
      final profile = CareProfile.fromMap({
        ...map,
        'id': 'demo',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      await FirestoreService.createProfile(profile);
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Demo profile "Mom" created — check Care Profiles.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: FilledButton.icon(
        onPressed: _loading ? null : _seed,
        icon: _loading
            ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add_rounded),
        label: const Text('Load demo profile (Mom)'),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String image, text;
  final VoidCallback onPress;

  const _Item({
    required this.image,
    required this.text,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: GestureDetector(
        onTap: onPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppImage(image, height: 32.h, width: 32.h),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                AppImage('arrow_right.svg', height: 20.h, width: 20.h),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

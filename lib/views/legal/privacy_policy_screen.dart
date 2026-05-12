import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/config/env_config.dart';
import '../../core/logic/helper_methods.dart';
import '../../core/theme.dart';

/// Privacy Policy screen.
///
/// Opens the live policy URL when the user taps "Open full policy".
/// In-app copy is a placeholder until the full legal text is ready.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your privacy is at the heart of Crucue.',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTheme.fontFamily2,
              ),
            ),
            SizedBox(height: 20.h),
            _PolicySection(
              title: 'What we collect',
              body:
                  'Crucue stores your care notes, incident logs, support plans, and reflections in your private Firebase account. '
                  'Voice recordings are processed securely and deleted after transcription. '
                  'We collect basic analytics (event counts, feature usage) with no personally identifiable information.',
            ),
            _PolicySection(
              title: 'How we use it',
              body:
                  'Your data is used exclusively to generate support plans and insights for you. '
                  'We never sell, share, or train models on your personal care data. '
                  'AI inference is performed on Google Cloud infrastructure using your anonymized context.',
            ),
            _PolicySection(
              title: 'On-device privacy',
              body:
                  'When on-device AI mode is enabled on supported devices, your care data never leaves your device during AI inference. '
                  'Only your own Firestore documents (scoped to your user ID) are stored in the cloud.',
            ),
            _PolicySection(
              title: 'Your rights',
              body:
                  'You can delete your account and all associated data at any time from Settings → Delete Account. '
                  'All care data is deleted immediately upon account deletion.',
            ),
            _PolicySection(
              title: 'Contact',
              body: 'Questions? Reach us at ${EnvConfig.supportEmail}',
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open full policy'),
              onPressed: () => openUrl(EnvConfig.privacyPolicyUrl),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            body,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

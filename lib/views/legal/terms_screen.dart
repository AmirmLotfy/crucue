import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/config/env_config.dart';
import '../../core/logic/helper_methods.dart';
import '../../core/theme.dart';

/// Terms of Service screen.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: AppTheme.fontFamily2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Last updated: April 2026',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).hintColor,
              ),
            ),
            SizedBox(height: 20.h),
            _TermsSection(
              title: '1. Service description',
              body:
                  'Crucue is a private caregiving support application that uses AI to help caregivers navigate difficult moments. '
                  'Crucue is not a licensed medical, therapeutic, or legal service. '
                  'All AI-generated content is supportive guidance only and should not replace professional advice.',
            ),
            _TermsSection(
              title: '2. Acceptable use',
              body:
                  'You agree to use Crucue only for its intended purpose — supporting caregiving for yourself and your loved ones. '
                  'You may not use Crucue to store data about individuals without their knowledge, '
                  'or for any purpose that violates applicable laws.',
            ),
            _TermsSection(
              title: '3. Data and privacy',
              body:
                  'Your care data is private and owned by you. '
                  'See our Privacy Policy for details on how we handle your information. '
                  'You can delete all your data at any time from the app settings.',
            ),
            _TermsSection(
              title: '4. Disclaimer',
              body:
                  'Crucue is provided "as is" without warranties of any kind. '
                  'We are not responsible for decisions made based on AI-generated support plans. '
                  'Always consult qualified professionals for medical, therapeutic, or legal decisions.',
            ),
            _TermsSection(
              title: '5. Contact',
              body: 'Questions? Contact us at ${EnvConfig.supportEmail}',
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open full terms'),
              onPressed: () => openUrl(EnvConfig.termsUrl),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

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

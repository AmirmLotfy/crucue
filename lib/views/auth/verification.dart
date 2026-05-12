import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/core/theme.dart';

import '../auth/login.dart';

/// Email verification screen — shown after registration.
/// The primary verification flow is via Firebase email link.
/// This screen prompts the user to check their email.
class VerificationView extends StatelessWidget {
  final String email;

  const VerificationView({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                size: 72.sp,
                color: AppTheme.primary,
              ),
              SizedBox(height: 32.h),
              Text(
                'Check your email',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: AppTheme.fontFamily2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'We sent a verification link to\n$email\n\nPlease click the link in your email to verify your account, then sign in.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).hintColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              FilledButton(
                onPressed: () =>
                    navigateTo(const LoginView(), keepHistory: false),
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

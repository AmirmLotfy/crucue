import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/branding/crucue_brand_logo.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/core/theme.dart';
import 'package:crucue/views/auth/login.dart';
import 'package:crucue/views/auth/register.dart';

import '../../core/design/app_button.dart';


class LoginOrRegisterView extends StatelessWidget {
  const LoginOrRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3,),
              Center(
                child: CrucueBrandLogo(
                  forDarkBackground: isDark,
                  maxHeight: 112.h,
                  maxWidth: 320.w,
                ),
              ),
              const Spacer(flex: 2,),
              Text(
                "Connect Better, Grow\nTogether",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  fontFamily: AppTheme.fontFamily2,
                ),
              ),
              SizedBox(height: 44.h),
              AppButton(
                onPress: () {
                  navigateTo(const RegisterView());
                },
                text: "Create Account",
              ),
              TextButton(
                onPressed: () {
                navigateTo(const LoginView());
                },
                child: const Text("Log In to Your Account"),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

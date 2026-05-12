import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/design/app_button.dart';
import 'package:crucue/core/design/app_input.dart';
import 'package:crucue/core/logic/cache_helper.dart';
import 'package:crucue/core/branding/crucue_brand_logo.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/core/logic/input_validator.dart';
import 'package:crucue/views/auth/forget_password.dart';
import 'package:crucue/views/home/view.dart';

import '../../core/theme.dart';
import 'components/login_or_register.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (credential.user!.emailVerified) {
        // Load user profile from Firestore
        final uid = credential.user!.uid;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          await CacheHelper.saveUserData(
            firstName: data['firstName'] as String? ?? '',
            lastName: data['lastName'] as String? ?? '',
            email: data['email'] as String? ?? _emailController.text.trim(),
            image: data['photoUrl'] as String? ?? data['image'] as String? ?? '',
          );
        }
        showMessage('Welcome back!', type: MessageType.success);
        navigateTo(const HomeView(), keepHistory: false);
      } else {
        showMessage(
          'Please verify your email before signing in.',
          type: MessageType.warning,
        );
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          showMessage('No account found with this email.');
          break;
        case 'wrong-password':
        case 'invalid-credential':
          showMessage('Incorrect email or password.');
          break;
        case 'too-many-requests':
          showMessage('Too many attempts. Please try again later.');
          break;
        default:
          showMessage(e.message ?? 'Sign in failed. Please try again.');
      }
    } catch (e) {
      showMessage('Something went wrong. Please try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                Center(
                  child: CrucueBrandLogo(
                    forDarkBackground:
                        Theme.of(context).brightness == Brightness.dark,
                    maxHeight: 56.h,
                    maxWidth: 260.w,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Care, guided by insight.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: AppTheme.fontFamily2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Sign in to continue supporting the people you love.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 36.h),
                AppInput(
                  label: 'Email Address',
                  controller: _emailController,
                  prefix: 'mail.svg',
                  hint: 'Your email address',
                  validator: (v) => InputValidator.emailValidator(v!),
                  keyboardType: TextInputType.emailAddress,
                ),
                AppInput(
                  label: 'Password',
                  controller: _passwordController,
                  inputType: InputType.password,
                  prefix: 'password.svg',
                  hint: 'Your password',
                  marginBottom: 8.h,
                  validator: (v) => InputValidator.passwordLoginValidator(v!),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => navigateTo(const ForgetPasswordView()),
                    child: const Text('Forgot password?'),
                  ),
                ),
                SizedBox(height: 16.h),
                AppButton(
                  isLoading: _isLoading,
                  onPress: _signIn,
                  text: 'Sign In',
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your data is private and encrypted.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                const LoginOrRegister(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/branding/crucue_brand_logo.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/core/theme.dart';
import 'package:crucue/views/auth/login.dart';

import '../../core/design/app_button.dart';
import '../../core/design/app_input.dart';
import '../../core/logic/input_validator.dart';
import 'components/login_or_register.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;
      final displayName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'displayName': displayName,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await credential.user!.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      showMessage(
        'Account created! Please verify your email before signing in.',
        type: MessageType.success,
      );
      navigateTo(const LoginView(), keepHistory: false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        showMessage('Please choose a stronger password.');
      } else if (e.code == 'email-already-in-use') {
        showMessage('An account with this email already exists.');
      } else {
        showMessage(e.message ?? 'Something went wrong. Please try again.');
      }
    } catch (e) {
      showMessage('Something went wrong. Please try again.');
    }
    if (mounted) setState(() => isLoading = false);
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
                SizedBox(height: 28.h),
                Center(
                  child: CrucueBrandLogo(
                    forDarkBackground:
                        Theme.of(context).brightness == Brightness.dark,
                    maxHeight: 52.h,
                    maxWidth: 260.w,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Care, guided by insight.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.h),
                Text(
                  'Create your account',
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
                  'Private. Secure. Just for you.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                AppInput(
                  controller: _firstNameController,
                  label: 'First Name',
                  prefix: 'user_name.svg',
                  hint: 'Enter your first name',
                  validator: (v) => InputValidator.nameValidator(v),
                ),
                AppInput(
                  controller: _lastNameController,
                  label: 'Last Name',
                  prefix: 'user_name.svg',
                  hint: 'Enter your last name',
                  validator: (v) =>
                      InputValidator.requiredValidator(v, fieldName: 'Last name'),
                ),
                AppInput(
                  controller: _emailController,
                  label: 'Email Address',
                  prefix: 'mail.svg',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => InputValidator.emailValidator(v!),
                ),
                AppInput(
                  controller: _passwordController,
                  label: 'Password',
                  inputType: InputType.password,
                  prefix: 'password.svg',
                  hint: 'Create a password (8+ characters)',
                  marginBottom: 8.h,
                  validator: (v) =>
                      InputValidator.passwordLoginValidator(v!),
                ),
                SizedBox(height: 24.h),
                AppButton(
                  isLoading: isLoading,
                  onPress: _register,
                  text: 'Create Account',
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
                const LoginOrRegister(isLogin: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/design/app_button.dart';
import 'package:crucue/core/design/app_input.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/views/auth/login.dart';

import '../../core/logic/cache_helper.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool isLoading = false;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: CacheHelper.email,
          password: _passwordController.text,
        ),
      );

      final uid = user.uid;

      // Delete Firestore user data
      await FirestoreService.deleteUser(uid);

      // Delete storage files
      if (CacheHelper.image.isNotEmpty) {
        await StorageService.deleteFile(CacheHelper.image);
      }

      // Delete Firebase Auth account
      await user.delete();
      await CacheHelper.logOut();

      navigateTo(const LoginView(), keepHistory: false);
      showMessage(
        'Your account has been deleted.',
        type: MessageType.success,
      );
    } on FirebaseAuthException catch (ex) {
      if (mounted) Navigator.pop(context);
      showMessage(_authErrorMessage(ex.code));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showMessage('Something went wrong. Please try again.');
    }
    if (mounted) setState(() => isLoading = false);
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Could not verify your identity. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(24.r),
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 48.sp,
          color: AppTheme.warmCoral,
        ),
        SizedBox(height: 16.h),
        Text(
          'Delete Your Account?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'This will permanently delete your account and all your care profiles, plans, and history. This cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).hintColor,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24.h),
        AppInput(
          label: 'Confirm Password',
          hint: 'Enter your password to confirm',
          controller: _passwordController,
          inputType: InputType.password,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: AppButton(
                isLoading: isLoading,
                onPress: _passwordController.text.isNotEmpty
                    ? _deleteAccount
                    : null,
                text: 'Delete Account',
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}




import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crucue/core/design/app_button.dart';
import 'package:crucue/core/logic/cache_helper.dart';
import 'package:crucue/core/logic/helper_methods.dart';

import '../../core/design/app_image.dart';
import '../../core/design/app_input.dart';
import '../../core/design/second_app_bar.dart';
import '../../core/theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String? _selectedImagePath;
  final _firstNameController =
      TextEditingController(text: CacheHelper.firstName);
  final _lastNameController =
      TextEditingController(text: CacheHelper.lastName);
  final _emailController = TextEditingController(text: CacheHelper.email);
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_selectedImagePath != null) {
        final ref = FirebaseStorage.instance
            .ref('users/$uid/profile_photo.jpg');
        await ref.putFile(File(_selectedImagePath!));
        imageUrl = await ref.getDownloadURL();
      }

      final displayName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'displayName': displayName,
        if (imageUrl != null) 'photoUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await CacheHelper.saveUserData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        image: imageUrl ?? CacheHelper.image,
      );

      showMessage('Profile updated.', type: MessageType.success);
    } catch (e) {
      showMessage('Could not save changes. Please try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SecondAppBar(text: 'Profile'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.h),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final image = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 60);
                  if (image != null) {
                    setState(() => _selectedImagePath = image.path);
                  }
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      height: 88.h,
                      width: 88.h,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: AppImage(
                        _selectedImagePath ?? CacheHelper.image,
                        height: 88.h,
                        width: 88.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 14.sp),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),
            AppInput(
              label: 'First Name',
              controller: _firstNameController,
              prefix: 'user_name.svg',
              hint: 'Your first name',
            ),
            AppInput(
              label: 'Last Name',
              controller: _lastNameController,
              prefix: 'user_name.svg',
              hint: 'Your last name',
            ),
            AbsorbPointer(
              child: Opacity(
                opacity: 0.5,
                child: AppInput(
                  controller: _emailController,
                  label: 'Email Address',
                  prefix: 'mail.svg',
                  hint: 'Your email address',
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ),
            Text(
              'Email cannot be changed after registration.',
              style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
            ),
            SizedBox(height: 24.h),
            AppButton(
              isLoading: _isLoading,
              onPress: _saveChanges,
              text: 'Save Changes',
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crucue/core/logic/cache_helper.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/views/home/view.dart';

import '../register.dart';

class LoginOrRegister extends StatelessWidget {
  final bool isLogin;

  const LoginOrRegister({super.key, this.isLogin = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLogin ? "Don't have an account?" : 'Already have an account?',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: () {
                if (isLogin) {
                  navigateTo(const RegisterView());
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(
                isLogin ? 'Sign Up' : 'Sign In',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return;

    // Create/update Firestore record on first Google sign-in
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      final nameParts = (user.displayName ?? '').split(' ');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'displayName': user.displayName ?? '',
        'firstName': nameParts.first,
        'lastName': nameParts.length > 1 ? nameParts.last : '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final data = doc.exists ? doc.data()! : {};
    await CacheHelper.saveUserData(
      firstName: data['firstName'] as String? ?? user.displayName?.split(' ').first ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: user.email ?? '',
      image: user.photoURL ?? '',
    );

    navigateTo(const HomeView(), keepHistory: false);
  } catch (e) {
    showMessage('Google sign-in failed. Please try again.');
  }
}

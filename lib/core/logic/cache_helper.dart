import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/constants.dart';

class CacheHelper {
  static late SharedPreferences _ref;

  static Future<void> init() async {
    _ref = await SharedPreferences.getInstance();
  }

  // ─── Auth / Session ──────────────────────────────────────────────

  static bool get isFirstTime =>
      _ref.getBool(AppConstants.keyIsFirstTime) ?? true;

  static Future<void> setNotFirstTime() async {
    await _ref.setBool(AppConstants.keyIsFirstTime, false);
  }

  // ─── User Profile (local cache) ──────────────────────────────────

  static String get firstName =>
      _ref.getString(AppConstants.keyFirstName) ?? '';

  static String get lastName =>
      _ref.getString(AppConstants.keyLastName) ?? '';

  static String get name {
    final f = firstName;
    final l = lastName;
    if (f.isEmpty && l.isEmpty) return '';
    if (l.isEmpty) return f;
    return '$f $l';
  }

  static String get email => _ref.getString(AppConstants.keyEmail) ?? '';

  static String get image => _ref.getString(AppConstants.keyImage) ?? '';

  static String? get activeProfileId =>
      _ref.getString(AppConstants.keyActiveProfileId);

  // ─── Save Methods ────────────────────────────────────────────────

  static Future<void> saveUserData({
    required String firstName,
    required String lastName,
    required String email,
    String image = '',
  }) async {
    await Future.wait([
      _ref.setString(AppConstants.keyFirstName, firstName),
      _ref.setString(AppConstants.keyLastName, lastName),
      _ref.setString(AppConstants.keyEmail, email),
      _ref.setString(AppConstants.keyImage, image),
    ]);
    debugPrint('[CacheHelper] User data saved for $email');
  }

  static Future<void> updateImage(String imageUrl) async {
    await _ref.setString(AppConstants.keyImage, imageUrl);
  }

  static Future<void> setActiveProfileId(String profileId) async {
    await _ref.setString(AppConstants.keyActiveProfileId, profileId);
  }

  // ─── Theme Mode ──────────────────────────────────────────────────

  static const _keyThemeMode = 'themeMode';

  /// Returns the persisted [ThemeMode], defaulting to [ThemeMode.system].
  static ThemeMode get savedThemeMode {
    final value = _ref.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }
    await _ref.setString(_keyThemeMode, value);
  }

  // ─── Session Teardown ────────────────────────────────────────────

  static Future<void> logOut() async {
    final installationId = _ref.getString(AppConstants.keyInstallationId);
    await _ref.clear();
    if (installationId != null && installationId.isNotEmpty) {
      await _ref.setString(AppConstants.keyInstallationId, installationId);
    }
    await setNotFirstTime();
  }

  /// Per-device install id for `users/{uid}/devices/{installationId}` FCM docs.
  static Future<String> getOrCreateInstallationId() async {
    final existing = _ref.getString(AppConstants.keyInstallationId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    await _ref.setString(AppConstants.keyInstallationId, id);
    return id;
  }
}

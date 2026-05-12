import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Crucue semantic color token system.
///
/// All UI code should reference these tokens rather than raw hex values.
/// Light/dark mode variants are expressed through [AppTheme.light] and
/// [AppTheme.dark] — widgets that need to switch should use
/// `Theme.of(context).colorScheme` or the convenience getters below.
class CrucueTokens {
  CrucueTokens._();

  // ─── Brand ──────────────────────────────────────────────────────────────
  /// Core brand orange — unchanged from the original Crucue identity.
  static const brandPrimary = Color(0xffFF4F00);
  static const brandPrimaryLight = Color(0xffFF6A2A);  // Pressed / hover
  static const brandPrimaryDark = Color(0xffCC3F00);   // Darker variant
  static const brandPrimarySubtle = Color(0xffFFF0E6); // Light-mode bg tint

  // ─── Surfaces (light) ───────────────────────────────────────────────────
  static const surfaceLight = Color(0xffffffff);
  static const surfaceAltLight = Color(0xffFAFAFA);
  static const surfaceElevatedLight = Color(0xffFFFFFF);
  static const inputSurfaceLight = Color(0xffFAFAFA);
  static const backgroundLight = Color(0xffF5F5F5);

  // ─── Surfaces (dark) ────────────────────────────────────────────────────
  static const backgroundDark = Color(0xff121212);
  static const surfaceDark = Color(0xff1E1E1E);
  static const surfaceAltDark = Color(0xff242424);
  static const surfaceElevatedDark = Color(0xff2A2A2A);
  static const inputSurfaceDark = Color(0xff2A2A2A);

  // ─── Borders (light) ────────────────────────────────────────────────────
  static const borderLight = Color(0xffEEEEEE);
  static const borderStrongLight = Color(0xffD1D5DB);

  // ─── Borders (dark) ─────────────────────────────────────────────────────
  static const borderDark = Color(0xff333333);
  static const borderStrongDark = Color(0xff555555);

  // ─── Text (light) ───────────────────────────────────────────────────────
  static const textPrimaryLight = Color(0xff191919);
  static const textSecondaryLight = Color(0xff8C8C8C);
  static const textMutedLight = Color(0xffAAAAAA);

  // ─── Text (dark) ────────────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xffE8E8E8);
  static const textSecondaryDark = Color(0xff9CA3AF);
  static const textMutedDark = Color(0xff666666);

  // ─── Semantic (mode-independent) ────────────────────────────────────────
  static const success = Color(0xff4CAF50);
  static const successSubtle = Color(0xffE8F5E9);
  static const warning = Color(0xffFF9800);
  static const warningSubtle = Color(0xffFFF3E0);
  static const error = Color(0xffEF233C);
  static const errorSubtle = Color(0xffFCE4EC);
  static const info = Color(0xff2196F3);
  static const infoSubtle = Color(0xffE3F2FD);

  // ─── Persona / relationship swatches ────────────────────────────────────
  // These are intentionally persona-specific and do not change with dark mode.
  static const personaChild = Color(0xffA6B2EE);
  static const personaTeenager = Color(0xffFFC2B8);
  static const personaBaby = Color(0xffFBB0FF);
  static const personaParent = Color(0xff7FD2F2);
  static const personaPartner = Color(0xffF3AEAF);
  static const personaSibling = Color(0xffBADED8);
  static const personaFriend = Color(0xffFEDEA5);
  static const personaPet = Color(0xffC2D6FE);
  static const personaMyself = Color(0xffEBCAE7);

  // Plan card accent swatches (used in ResultsView)
  static const planWhatHappening = Color(0xffFFF8E1);
  static const planWhatToDo = Color(0xffE8F5E9);
  static const planWhatToAvoid = Color(0xffFCE4EC);
  static const planMessage = Color(0xffE3F2FD);
  static const planTasks = Color(0xffF3E5F5);
  static const planReflect = Color(0xffE0F7FA);
}

/// Extension for quick access to semantic colors from [BuildContext].
extension AppColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface => Theme.of(this).colorScheme.surface;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
}

class AppTheme {
  AppTheme._();

  // ─── Kept for backward-compat references ───────────────────────────────
  static const primary = CrucueTokens.brandPrimary;
  static const primaryLight = CrucueTokens.brandPrimaryLight;
  static const primaryDark = CrucueTokens.brandPrimaryDark;

  // Light-mode surface tokens (use Theme.of(ctx) for dark-mode awareness)
  static const surface = CrucueTokens.surfaceLight;
  static const background = CrucueTokens.backgroundLight;
  static const inputBg = CrucueTokens.inputSurfaceLight;
  static const border = CrucueTokens.borderLight;
  static const textPrimary = CrucueTokens.textPrimaryLight;
  static const textSecondary = CrucueTokens.textSecondaryLight;
  static const hint = CrucueTokens.textMutedLight;
  static const divider = CrucueTokens.borderLight;

  // Semantic
  static const success = CrucueTokens.success;
  static const warning = CrucueTokens.warning;
  static const error = CrucueTokens.error;
  static const info = CrucueTokens.info;

  // Warm coral kept for backward compat
  static const warmCoral = Color(0xffE76F51);

  static const fontFamily = 'Roboto';
  static const fontFamily2 = 'Montserrat';

  static BorderRadius get radius => BorderRadius.circular(12.r);
  static BorderRadius get radiusLarge => BorderRadius.circular(20.r);

  // ─── Light Theme ─────────────────────────────────────────────────────
  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        scaffoldBg: CrucueTokens.backgroundLight,
        surfaceColor: CrucueTokens.surfaceLight,
        inputFillColor: CrucueTokens.inputSurfaceLight,
        textPrimaryColor: CrucueTokens.textPrimaryLight,
        textSecondaryColor: CrucueTokens.textSecondaryLight,
        hintColor: CrucueTokens.textMutedLight,
        borderColor: CrucueTokens.borderLight,
        dividerColor: CrucueTokens.borderLight,
        unselectedTrackColor: const Color(0xffD1D5DB),
        shadowOverlay: Colors.black,
      );

  // ─── Dark Theme ──────────────────────────────────────────────────────
  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        scaffoldBg: CrucueTokens.backgroundDark,
        surfaceColor: CrucueTokens.surfaceDark,
        inputFillColor: CrucueTokens.inputSurfaceDark,
        textPrimaryColor: CrucueTokens.textPrimaryDark,
        textSecondaryColor: CrucueTokens.textSecondaryDark,
        hintColor: CrucueTokens.textMutedDark,
        borderColor: CrucueTokens.borderDark,
        dividerColor: CrucueTokens.borderDark,
        unselectedTrackColor: const Color(0xff444444),
        shadowOverlay: Colors.black,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color inputFillColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color hintColor,
    required Color borderColor,
    required Color dividerColor,
    required Color unselectedTrackColor,
    required Color shadowOverlay,
  }) {
    const brandPrimary = CrucueTokens.brandPrimary;
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffoldBg,
      hintColor: hintColor,
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        space: 1,
        thickness: 1,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        brightness: brightness,
        primary: brandPrimary,
        onPrimary: Colors.white,
        secondary: isDark ? CrucueTokens.brandPrimaryLight : brandPrimary,
        onSecondary: Colors.white,
        error: CrucueTokens.error,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        foregroundColor: textPrimaryColor,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
          color: textPrimaryColor,
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: brandPrimary,
        unselectedItemColor: textSecondaryColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 2 : 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brandPrimary
              : unselectedTrackColor,
        ),
        thumbColor: WidgetStateProperty.all(Colors.white),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? brandPrimary : null),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: CrucueTokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: CrucueTokens.error, width: 1.5),
        ),
        filled: true,
        fillColor: inputFillColor,
        hintStyle: TextStyle(color: hintColor, fontSize: 14.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brandPrimary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white,
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          fixedSize: Size.fromHeight(52.h),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandPrimary,
          side: const BorderSide(color: brandPrimary),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          fixedSize: Size.fromHeight(52.h),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPrimary,
          textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? CrucueTokens.surfaceAltDark : CrucueTokens.surfaceAltLight,
        selectedColor: brandPrimary.withValues(alpha: 0.15),
        side: BorderSide(color: borderColor),
        labelStyle: TextStyle(fontSize: 13.sp, color: textPrimaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? CrucueTokens.surfaceElevatedDark : textPrimaryColor,
        contentTextStyle: TextStyle(
          color: isDark ? textPrimaryColor : Colors.white,
          fontSize: 14.sp,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandPrimary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondaryColor,
        titleTextStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
      ),
    );
  }
}

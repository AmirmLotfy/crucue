import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full Crucue wordmark from [assets/Logos/](orange on light backgrounds, white on dark).
/// Uses [BoxFit.contain] so the asset’s aspect ratio is never stretched.
class CrucueBrandLogo extends StatelessWidget {
  const CrucueBrandLogo({
    super.key,
    required this.forDarkBackground,
    this.maxWidth,
    this.maxHeight,
    this.alignment = Alignment.center,
  });

  /// `true` → `crucue_logo_white.png` (for dark surfaces / dark mode).
  /// `false` → `crucue_logo_orange.png` (for light surfaces / light mode).
  final bool forDarkBackground;

  /// Cap width; height follows aspect ratio via [BoxFit.contain].
  final double? maxWidth;

  /// Cap height; width follows aspect ratio via [BoxFit.contain].
  final double? maxHeight;

  final Alignment alignment;

  static const String _orange = 'assets/Logos/crucue_logo_orange.png';
  static const String _white = 'assets/Logos/crucue_logo_white.png';
  static const String _fallback = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final path = forDarkBackground ? _white : _orange;
    final w = maxWidth ?? 280.w;
    final h = maxHeight ?? 96.h;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w, maxHeight: h),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          alignment: alignment,
          errorBuilder: (_, __, ___) => Image.asset(
            _fallback,
            fit: BoxFit.contain,
            alignment: alignment,
          ),
        ),
      ),
    );
  }
}

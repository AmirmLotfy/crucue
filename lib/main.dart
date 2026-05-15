import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'core/logic/cache_helper.dart';
import 'core/logic/firebase_notifications.dart';
import 'core/services/fcm_token_service.dart';
import 'core/theme.dart';
import 'firebase_options.dart';

/// Global analytics instance for logging events throughout the app.
final analytics = FirebaseAnalytics.instance;

Future<void> _activateAppCheckIfSupported() async {
  if (kIsWeb) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      break;
    default:
      return;
  }
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _activateAppCheckIfSupported();

  if (!kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        await FlutterGemma.initialize();
        break;
      default:
        break;
    }
  }

  // Catch Flutter framework errors (widget build errors etc.)
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch async errors that are not caught by Flutter's zone
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await CacheHelper.init();
  await GlobalNotification().setUpFirebase();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Wrap in zone to catch any remaining async errors in debug mode
  await runZonedGuarded(
    () async {
      runApp(const ProviderScope(child: CrucueApp()));
    },
    (error, stack) {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    },
  );
}

class CrucueApp extends ConsumerWidget {
  const CrucueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final uid = next.asData?.value?.uid;
      if (uid != null) {
        unawaited(FcmTokenService.syncForUser(uid));
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Crucue',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          builder: (context, child) {
            final brightness = Theme.of(context).brightness;
            final overlay = brightness == Brightness.dark
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: CrucueTokens.backgroundDark,
                    systemNavigationBarIconBrightness: Brightness.light,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: CrucueTokens.backgroundLight,
                    systemNavigationBarIconBrightness: Brightness.dark,
                  );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlay,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

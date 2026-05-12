import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/logic/helper_methods.dart';
import '../views/auth/splash.dart';
import '../views/auth/on_boarding.dart';
import '../views/auth/login_or_register.dart';
import '../views/home/view.dart';

/// Notifies [GoRouter] when [FirebaseAuth] session changes without recreating the router.
class AuthStateRefreshNotifier extends ChangeNotifier {
  AuthStateRefreshNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

final _authRefreshProvider = Provider<AuthStateRefreshNotifier>((ref) {
  final notifier = AuthStateRefreshNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// GoRouter instance. Uses the shared [navigatorKey] so existing
/// imperative [navigateTo] calls still work during migration.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_authRefreshProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loc = state.matchedLocation;

      final onPublicRoute = loc.startsWith('/splash') ||
          loc.startsWith('/onboarding') ||
          loc.startsWith('/auth');

      if (user == null && !onPublicRoute) return '/splash';
      if (user != null &&
          user.emailVerified &&
          onPublicRoute &&
          !loc.startsWith('/splash')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnBoardingView(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginOrRegisterView(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeView(),
      ),
    ],
  );
});

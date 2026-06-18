import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/deal/presentation/welcome_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
}

final _authListenableProvider = Provider<ValueNotifier<AppAuthState?>>((ref) {
  final notifier = ValueNotifier<AppAuthState?>(null);
  ref.listen(authProvider, (_, next) {
    next.whenData((state) => notifier.value = state);
  });
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(_authListenableProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = authListenable.value;
      final status = authState?.status;

      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (status == null || status == AuthStatus.initial || status == AuthStatus.loading) {
        return AppRoutes.splash;
      }
      if (status == AuthStatus.authenticated && isAuthRoute) {
        return AppRoutes.home;
      }
      if (status == AuthStatus.authenticated && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.home;
      }
      if (status != AuthStatus.authenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const WelcomeScreen(),
      ),
    ],
  );
});

class AppRouter {
  const AppRouter._();

  static GoRouter of(WidgetRef ref) => ref.watch(routerProvider);
}
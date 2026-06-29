import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/deal/domain/deal_model.dart';
import '../../features/deal/presentation/contracts_screen.dart';
import '../../features/deal/presentation/create_deal_screen.dart';
import '../../features/deal/presentation/deal_detail_screen.dart';
import '../../features/deal/presentation/deals_list_screen.dart';
import '../../features/deal/presentation/home_screen.dart';
import '../../features/kyc/presentation/kyc_status_screen.dart';
import '../../features/kyc/presentation/kyc_upload_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const otp = '/otp';
  static const home = '/home';
  static const kycStatus = '/kyc';
  static const kycUpload = '/kyc/upload';
  static const deals = '/deals';
  static const createDeal = '/deals/create';
  static const dealDetail = '/deals/detail';
  static const contracts = '/contracts';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const chat = '/chat';
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
      final isResetPasswordDeepLink = _isResetPasswordDeepLink(state);

      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.otp,
        AppRoutes.resetPassword,
      ].contains(state.matchedLocation);

      if (isResetPasswordDeepLink &&
          state.matchedLocation != AppRoutes.resetPassword) {
        return AppRoutes.resetPassword;
      }

      if (status == null || status == AuthStatus.initial) {
        return isResetPasswordDeepLink
            ? AppRoutes.resetPassword
            : AppRoutes.splash;
      }
      if (status == AuthStatus.loading && !isAuthRoute) {
        return isResetPasswordDeepLink
            ? AppRoutes.resetPassword
            : AppRoutes.splash;
      }

      if (status == AuthStatus.passwordRecovery) {
        if (state.matchedLocation != AppRoutes.resetPassword) {
          return AppRoutes.resetPassword;
        }
        return null;
      }

      if (status == AuthStatus.authenticated) {
        if (isAuthRoute || state.matchedLocation == AppRoutes.splash) {
          return AppRoutes.home;
        }
        return null;
      }

      if (!isAuthRoute && state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _fadePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (context, state) =>
            _fadePage(state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) {
          final email = state.extra as String;
          return _fadePage(state, OtpScreen(email: email));
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _sectionPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.kycStatus,
        pageBuilder: (context, state) =>
            _sectionPage(state, const KycStatusScreen()),
      ),
      GoRoute(
        path: AppRoutes.kycUpload,
        pageBuilder: (context, state) =>
            _flowPage(state, const KycUploadScreen()),
      ),
      GoRoute(
        path: AppRoutes.deals,
        pageBuilder: (context, state) =>
            _sectionPage(state, const DealsListScreen()),
      ),
      GoRoute(
        path: AppRoutes.createDeal,
        pageBuilder: (context, state) =>
            _flowPage(state, const CreateDealScreen()),
      ),
      GoRoute(
        path: AppRoutes.dealDetail,
        pageBuilder: (context, state) {
          final deal = state.extra as Deal;
          return _flowPage(state, DealDetailScreen(deal: deal));
        },
      ),
      GoRoute(
        path: AppRoutes.contracts,
        pageBuilder: (context, state) =>
            _sectionPage(state, const ContractsScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _sectionPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            _sectionPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) =>
            _flowPage(state, const ChatScreen()),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
    ],
  );
});

class AppRouter {
  const AppRouter._();

  static GoRouter of(WidgetRef ref) => ref.watch(routerProvider);
}

Page<void> _sectionPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 160),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

Page<void> _flowPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(0.03, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
      final opacity = CurvedAnimation(parent: animation, curve: Curves.easeOut);

      return FadeTransition(
        opacity: opacity,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}

bool _isResetPasswordDeepLink(GoRouterState state) {
  final uri = state.uri;
  return uri.scheme == 'io.supabase.idealapp' &&
      (uri.host == 'reset-password' ||
          uri.path == '/reset-password' ||
          state.matchedLocation == AppRoutes.resetPassword);
}

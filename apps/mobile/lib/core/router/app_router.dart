import '../../features/chat/presentation/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/template/domain/template_model.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/deal/domain/deal_model.dart';
import '../../features/deal/presentation/contracts_screen.dart';
import '../../features/deal/presentation/create_deal_screen.dart';
import '../../features/deal/presentation/deal_chat_screen.dart';
import '../../features/deal/presentation/deal_detail_screen.dart';
import '../../features/deal/presentation/deal_share_screen.dart';
import '../../features/deal/presentation/deals_list_screen.dart';
import '../../features/deal/presentation/home_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/documents/presentation/my_contracts_screen.dart';
import '../../features/kyc/presentation/kyc_status_screen.dart';
import '../../features/kyc/presentation/kyc_upload_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/template/presentation/template_form_screen.dart';

class AppRoutes {
  const AppRoutes._();
  static const String dealAiAssistant = chat;
  static const String chat = '/chat';
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String otp = '/otp';

  static const String home = '/home';

  static const String kycStatus = '/kyc';
  static const String kycUpload = '/kyc/upload';

  static const String deals = '/deals';
  static const String createDeal = '/deals/create';
  static const String dealCreateStart = createDeal;
  static const String dealDetail = '/deals/detail';
  static const String dealShare = '/deals/share';
  static const String dealChat = '/deals/chat';

  static const String contracts = '/contracts';
  static const String myContracts = '/my-contracts';
  static const String documents = '/documents';

  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit';

  static const String templateForm = '/templates/form';
}

final _authListenableProvider = Provider<ValueNotifier<AppAuthState?>>((ref) {
  final notifier = ValueNotifier<AppAuthState?>(null);

  ref.listen(authProvider, (_, next) {
    next.whenData((state) {
      notifier.value = state;
    });
  });

  ref.onDispose(notifier.dispose);

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

      final isAuthRoute = <String>[
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.otp,
        AppRoutes.resetPassword,
      ].contains(state.matchedLocation);

      if (status == null || status == AuthStatus.initial) {
        return AppRoutes.splash;
      }

      if (status == AuthStatus.loading && !isAuthRoute) {
        return AppRoutes.splash;
      }

      if (status == AuthStatus.passwordRecovery) {
        return state.matchedLocation == AppRoutes.resetPassword
            ? null
            : AppRoutes.resetPassword;
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
        pageBuilder: (context, state) {
          return _fadePage(state, const SplashScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) {
          return _fadePage(state, const LoginScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) {
          return _fadePage(state, const RegisterScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) {
          return _fadePage(state, const ForgotPasswordScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        pageBuilder: (context, state) {
          final email = state.extra as String;

          return _fadePage(state, ResetPasswordScreen(email: email));
        },
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
        pageBuilder: (context, state) {
          return _sectionPage(state, const HomeScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.kycStatus,
        pageBuilder: (context, state) {
          return _sectionPage(state, const KycStatusScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.kycUpload,
        pageBuilder: (context, state) {
          return _flowPage(state, const KycUploadScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.deals,
        pageBuilder: (context, state) {
          return _sectionPage(state, const DealsListScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.createDeal,
        pageBuilder: (context, state) {
          return _flowPage(state, const CreateDealScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.dealDetail,
        pageBuilder: (context, state) {
          final deal = state.extra as Deal;

          return _flowPage(state, DealDetailScreen(deal: deal));
        },
      ),
      GoRoute(
        path: AppRoutes.dealShare,
        pageBuilder: (context, state) {
          final deal = state.extra as Deal;

          return _flowPage(state, DealShareScreen(deal: deal));
        },
      ),
      GoRoute(
        path: AppRoutes.dealChat,
        pageBuilder: (context, state) {
          final deal = state.extra as Deal;

          return _flowPage(state, DealChatScreen(deal: deal));
        },
      ),
      GoRoute(
        path: AppRoutes.contracts,
        pageBuilder: (context, state) {
          return _sectionPage(state, const ContractsScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.myContracts,
        pageBuilder: (context, state) {
          return _sectionPage(state, const MyContractsScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.documents,
        pageBuilder: (context, state) {
          return _sectionPage(state, const DocumentsScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) {
          return _sectionPage(state, const NotificationsScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) {
          return _sectionPage(state, const SettingsScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) {
          return _flowPage(state, const EditProfileScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) {
          return _flowPage(state, const ChatScreen());
        },
      ),
      GoRoute(
        path: AppRoutes.templateForm,
        pageBuilder: (context, state) {
          final extra = state.extra;

          final DealTemplate? template = extra is DealTemplate ? extra : null;

          return _flowPage(state, TemplateFormScreen(template: template));
        },
      ),
      GoRoute(
  path: '/chat',
  name: 'chat',
  builder: (context, state) => const ChatScreen(),
),
    ],
  );
});

class AppRouter {
  const AppRouter._();

  static GoRouter of(WidgetRef ref) {
    return ref.watch(routerProvider);
  }
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

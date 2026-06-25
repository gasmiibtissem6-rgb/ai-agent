import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/deals/deals_screen.dart';
import '../screens/deals/deal_details_screen.dart';
import '../screens/deals/create_deal_screen.dart';
import '../screens/contracts/contracts_screen.dart';
import '../screens/contracts/contract_details_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/identity_verification_screen.dart';
import '../screens/profile/trust_score_screen.dart';
import '../screens/settings/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Main Routes
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/deals',
      builder: (context, state) => const DealsScreen(),
    ),
    GoRoute(
      path: '/deal/:id',
      builder: (context, state) => DealDetailsScreen(
        dealId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) => const CreateDealScreen(),
    ),
    GoRoute(
      path: '/contracts',
      builder: (context, state) => const ContractsScreen(),
    ),
    GoRoute(
      path: '/contract/:id',
      builder: (context, state) => ContractDetailsScreen(
        contractId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // Profile Routes
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/identity-verification',
      builder: (context, state) => const IdentityVerificationScreen(),
    ),
    GoRoute(
      path: '/trust-score',
      builder: (context, state) => const TrustScoreScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);

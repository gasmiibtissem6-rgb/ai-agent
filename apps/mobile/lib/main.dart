import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/env.dart';
import 'core/theme/theme.dart';
import 'features/auth/domain/auth_provider.dart';
import 'services/supabase_service.dart';
import 'core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: IdealApp()));
}

class IdealApp extends ConsumerWidget {
  const IdealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.of(ref);
    return MaterialApp.router(
      title: 'IDEAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
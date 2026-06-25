import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants/env.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/supabase_service.dart';
import 'core/router/app_router.dart';
import 'core/security/security_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await SecurityConfig.runStartupChecks();
  await _bootstrapTheme();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: IdealApp()));
}

Future<void> _bootstrapTheme() async {
  const storage = FlutterSecureStorage();
  try {
    final themeMode = await storage.read(key: 'theme_mode');
    AppColors.isDarkMode = themeMode != 'light';
  } catch (_) {
    AppColors.isDarkMode = true;
  }
}

class IdealApp extends ConsumerWidget {
  const IdealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.of(ref);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'IDEAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ideal_app/core/constants/app_colors.dart';
import 'package:ideal_app/core/theme/theme.dart';
import 'package:ideal_app/core/theme/theme_provider.dart';
import 'package:ideal_app/core/theme/theme_toggle_button.dart';
import 'package:ideal_app/features/deal/presentation/home_screen.dart';

/// go_router caches the visible page, so a screen styled with [AppColors]
/// getters only re-resolves its colors when something makes it rebuild.
/// The Home screen hosts the theme toggle and must therefore watch
/// [themeProvider]; otherwise toggling leaves stale colors on screen
/// (dark cards on a light scaffold and vice versa).
void main() {
  testWidgets('toggling the theme from Home restyles the screen in place', (
    tester,
  ) async {
    AppColors.isDarkMode = true;
    final darkCard = AppColors.card;
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ref.watch(themeProvider),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    bool hasCardColored(Color color) => tester
        .widgetList<Container>(find.byType(Container))
        .any((c) => (c.decoration as BoxDecoration?)?.color == color);

    expect(hasCardColored(darkCard), isTrue, reason: 'dark cards on screen');

    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();

    final lightCard = AppColors.card;
    expect(AppColors.isDarkMode, isFalse);
    expect(
      hasCardColored(lightCard),
      isTrue,
      reason: 'cards must re-resolve to the light palette immediately',
    );
    expect(
      hasCardColored(darkCard),
      isFalse,
      reason: 'no stale dark-mode cards may remain after toggling',
    );
  });
}

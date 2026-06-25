import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ideal_app/core/theme/theme.dart';
import 'package:ideal_app/shared/ideal_ui.dart';

void main() {
  testWidgets('shows the IDEAL brand shell components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AuthShell(
            title: 'Welcome back',
            subtitle: 'Sign in to continue managing trusted deals.',
            child: Text('Sign In'),
          ),
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(IdealLogo), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ideal_app/main.dart';

void main() {
  testWidgets('shows the IDEAL welcome screen', (tester) async {
    await tester.pumpWidget(const IdealApp());

    expect(find.text('IDEAL'), findsOneWidget);
    expect(find.text('Main areas'), findsOneWidget);
    expect(find.text('Deals'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Contracts'), 200);
    expect(find.text('Contracts'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Approvals'), 200);
    expect(find.text('Approvals'), findsOneWidget);
  });
}

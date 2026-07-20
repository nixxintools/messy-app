import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:messy/app.dart';
import 'package:messy/ui/providers/providers.dart';

void main() {
  testWidgets('first launch shows onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appGateProvider.overrideWith((ref) async => AppGate.onboarding),
        ],
        child: const MessyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Messy'), findsOneWidget);
    expect(find.text('Create my identity'), findsOneWidget);
  });

  testWidgets('locked gate shows the PIN screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appGateProvider.overrideWith((ref) async => AppGate.locked),
        ],
        child: const MessyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsOneWidget);
  });

  testWidgets('pin setup gate is mandatory on fresh identity',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appGateProvider.overrideWith((ref) async => AppGate.pinSetup),
        ],
        child: const MessyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set your PIN'), findsOneWidget);
  });
}

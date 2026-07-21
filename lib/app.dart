import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/providers/providers.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/security/pin_screens.dart';

const messyYellow = Color(0xFFFFD60A);
const messyOnYellow = Color(0xFF201A00);

/// ColorScheme.fromSeed desaturates the primary heavily in dark mode; pin
/// the roles that drive buttons/highlights to the true brand yellow.
ColorScheme _messyScheme() =>
    ColorScheme.fromSeed(seedColor: messyYellow, brightness: Brightness.dark)
        .copyWith(
      primary: messyYellow,
      onPrimary: messyOnYellow,
      primaryContainer: messyYellow,
      onPrimaryContainer: messyOnYellow,
      secondary: messyYellow,
      secondaryContainer: messyYellow,
      onSecondaryContainer: messyOnYellow,
      tertiary: messyYellow,
    );

ThemeData _messyTheme() {
  // Whole-app readability bump: every text style +1px. The delta must be
  // applied to a concrete typography (raw ThemeData styles have null sizes).
  final typography = Typography.material2021(platform: TargetPlatform.android);
  final sized = typography.englishLike
      .merge(typography.white)
      .apply(fontSizeDelta: 1);
  return ThemeData(
    colorScheme: _messyScheme(),
    useMaterial3: true,
    textTheme: sized,
  );
}

class MessyApp extends ConsumerWidget {
  const MessyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(appGateProvider);
    return MaterialApp(
      title: 'Messy',
      theme: _messyTheme(),
      home: gate.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
        data: (g) => switch (g) {
          AppGate.onboarding => const OnboardingScreen(),
          AppGate.pinSetup => const PinSetupScreen(),
          AppGate.locked => const PinLockScreen(),
          AppGate.ready => const HomeShell(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/providers/providers.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/security/pin_screens.dart';

const messyYellow = Color(0xFFFFD60A);

class MessyApp extends ConsumerWidget {
  const MessyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(appGateProvider);
    return MaterialApp(
      title: 'Messy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: messyYellow,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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

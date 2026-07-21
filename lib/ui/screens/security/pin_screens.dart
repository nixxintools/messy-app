import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/security/pin_service.dart';
import '../../providers/providers.dart';
import '../../widgets/web_logo.dart';

/// Mandatory PIN creation — shown during onboarding and whenever the gate is
/// enabled without a PIN on record.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    final pin = _pin.text;
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }
    if (pin != _confirm.text) {
      setState(() => _error = 'PINs don\'t match');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final pinService = ref.read(pinServiceProvider);
    await pinService.setPin(pin);
    await pinService.setEnabled(true);
    await pinService.markUnlocked();
    ref.invalidate(appGateProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: WebLogo(size: 56)),
              const SizedBox(height: 16),
              Text(
                'Set your PIN',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Messy is locked by default. Your PIN is required to open '
                'the app at least once a day.\nYou can turn this off later '
                'in Settings.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
              _PinField(controller: _pin, label: 'PIN (4+ digits)'),
              const SizedBox(height: 12),
              _PinField(
                controller: _confirm,
                label: 'Confirm PIN',
                onSubmitted: _save,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Lock it in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily unlock gate.
class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  final _pin = TextEditingController();
  String? _error;
  bool _checking = false;

  Future<void> _unlock() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final result = await ref.read(pinServiceProvider).verify(_pin.text);
    if (result is PinOk) {
      ref.invalidate(appGateProvider);
      return;
    }
    _pin.clear();
    setState(() {
      _checking = false;
      _error = switch (result) {
        PinLockedOut(:final retryInSeconds) =>
          'Too many attempts — wait ${retryInSeconds}s',
        PinWrong(:final attemptsLeftBeforeLockout)
            when attemptsLeftBeforeLockout > 0 =>
          'Wrong PIN · $attemptsLeftBeforeLockout left before lockout',
        _ => 'Wrong PIN',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: WebLogo(size: 56)),
              const SizedBox(height: 16),
              Text(
                'Enter your PIN',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 28),
              _PinField(
                controller: _pin,
                label: 'PIN',
                autofocus: true,
                onSubmitted: _unlock,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _checking ? null : _unlock,
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final Future<void> Function()? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(letterSpacing: 8, fontSize: 20),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}

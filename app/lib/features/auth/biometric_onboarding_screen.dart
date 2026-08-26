import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/app_auth_state.dart';
import '../splash/splash_screen.dart';
import 'widgets/biometric_opt_in_panel.dart';

/// The biometric opt-in, as its own route.
///
/// Assembly only: [BiometricOptInPanel] holds the interaction, so the panel
/// and its tests are shared with nothing else having to change.
class BiometricOnboardingScreen extends StatelessWidget {
  const BiometricOnboardingScreen({super.key});

  static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    final AppAuthState session = context.watch<AppAuthCubit>().state;

    // Holds the frame between answering the prompt and the router redirecting.
    if (session is! AppAuthPendingBiometricOptIn) {
      return const SplashScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: BiometricOptInPanel(user: session.user),
            ),
          ),
        ),
      ),
    );
  }
}

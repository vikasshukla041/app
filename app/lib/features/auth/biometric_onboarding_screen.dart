import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/app_auth_state.dart';
import '../../core/design_system/tokens/app_sizing.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../splash/splash_screen.dart';
import 'widgets/biometric_opt_in_panel.dart';

class BiometricOnboardingScreen extends StatelessWidget {
  const BiometricOnboardingScreen({super.key});

  // static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    final AppAuthState session = context.watch<AppAuthCubit>().state;

    if (session is! AppAuthPendingBiometricOptIn) {
      return const SplashScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizing.maxContentWidth,
              ),
              child: BiometricOptInPanel(user: session.user),
            ),
          ),
        ),
      ),
    );
  }
}

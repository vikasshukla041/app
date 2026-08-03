import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../auth_cubit.dart';
import '../auth_state.dart';
import 'biometric_opt_in_tile.dart';
import 'biometrics_button.dart';
import 'login_button.dart';
import 'password_text_field.dart';
import 'username_text_field.dart';

/// Assembles the login inputs and forwards user intent to [AuthCubit].
///
/// Stateful only because TextEditingControllers must be disposed and the
/// opt-in checkbox is ephemeral UI state. Contains zero business logic.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _enableBiometrics = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Trim only the username: a password may legitimately contain spaces.
  void _onLoginPressed() {
    context.read<AuthCubit>().login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      enableBiometrics: _enableBiometrics,
    );
  }

  void _onBiometricsPressed() {
    context.read<AuthCubit>().loginWithBiometrics(
      // The OS renders this string, so it must arrive already localized.
      reason: AppLocalizations.of(context).biometricPromptReason,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final bool isLoading = state is AuthLoading;
        final AuthInitial? resting = state is AuthInitial ? state : null;
        final bool canOfferSetup = resting?.canOfferBiometricSetup ?? false;
        final bool canUseBiometrics = resting?.canLoginWithBiometrics ?? false;

        return AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UsernameTextField(
                controller: _usernameController,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              PasswordTextField(
                controller: _passwordController,
                enabled: !isLoading,
                onSubmitted: (_) => _onLoginPressed(),
              ),
              if (canOfferSetup) ...<Widget>[
                const SizedBox(height: 8),
                BiometricOptInTile(
                  value: _enableBiometrics,
                  onChanged: isLoading
                      ? null
                      : (bool value) =>
                            setState(() => _enableBiometrics = value),
                ),
              ],
              const SizedBox(height: 24),
              LoginButton(
                onPressed: _onLoginPressed,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              // Always rendered so the option is discoverable; enabled only
              // once a saved session exists to unlock.
              BiometricsButton(
                onPressed: (canUseBiometrics && !isLoading)
                    ? _onBiometricsPressed
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

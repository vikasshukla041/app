import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth_cubit.dart';
import '../auth_state.dart';
import 'biometrics_button.dart';
import 'login_button.dart';
import 'password_text_field.dart';
import 'username_text_field.dart';

/// Assembles the login inputs and forwards user intent to [AuthCubit].
///
/// Stateful only because TextEditingControllers must be disposed.
/// Contains zero business logic.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final bool isLoading = state is AuthLoading;

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
              const SizedBox(height: 24),
              LoginButton(
                onPressed: _onLoginPressed,
                isLoading: isLoading,
              ),
              const SizedBox(height: 12),
              // Enabled once local_auth ships: requires biometric hardware
              // AND a previously stored token to authenticate against.
              const BiometricsButton(onPressed: null),
            ],
          ),
        );
      },
    );
  }
}

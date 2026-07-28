import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'email_text_field.dart';
import 'login_button.dart';
import 'password_text_field.dart';
import '../auth_state.dart';

// Login form containing Ui and login logic
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // controller read text by user
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    context.read<AuthCubit>().login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Sign In'),

        const SizedBox(height: 12),

        const Text('Enter your details to manage your trades.'),

        const SizedBox(height: 30),

        // EmailTextField(controller: _usernameController),
        Semantics(
          label: 'Username',
          textField: true,
          child: EmailTextField(controller: _usernameController),
        ),

        const SizedBox(height: 20),

        // PasswordTextField(controller: _passwordController),
        Semantics(
          label: 'Password',
          textField: true,
          child: PasswordTextField(controller: _passwordController),
        ),

        const SizedBox(height: 30),

        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Semantics(
              label: 'Sign In',
              button: true,
              child: LoginButton(
                isLoading: isLoading,
                onPressed: isLoading ? null : _onLoginPressed,
              ),
            );
          },
        ),
      ],
    );
  }
}


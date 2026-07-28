import 'package:flutter/material.dart';

// reusable password input filed
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        border: OutlineInputBorder(),
      ),
    );
  }
}


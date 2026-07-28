import 'package:flutter/material.dart';

class EmailTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const EmailTextField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        border: OutlineInputBorder(),
      ),
    );
  }
}


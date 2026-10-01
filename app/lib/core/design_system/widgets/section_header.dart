import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionPressed,
  }) : assert(
         (actionLabel == null) == (onActionPressed == null),
         'An action needs both a label and a callback',
       );

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final String? subtitle = this.subtitle;
    final String? actionLabel = this.actionLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          Semantics(
            label: actionLabel,
            button: true,
            child: TextButton(
              onPressed: onActionPressed,
              child: Text(actionLabel),
            ),
          ),
      ],
    );
  }
}

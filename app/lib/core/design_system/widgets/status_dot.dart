import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'app_tone.dart';

/// A coloured dot with a short explanation, for the live state of a figure.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.label, required this.tone});

  final String label;
  final AppTone tone;

  // Kept small: it's a marker, not a button.
  static const double _diameter = 6;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _diameter,
          height: _diameter,
          decoration: BoxDecoration(
            color: tone.accent(context),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // The label carries the meaning, so it keeps the ordinary muted colour.
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

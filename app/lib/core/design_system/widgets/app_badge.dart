import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_sizing.dart';
import '../tokens/app_spacing.dart';
import 'app_tone.dart';

/// A short, non-interactive label: an account tier, a settlement state, a count.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppTone.neutral,
    this.icon,
  });

  final String label;
  final AppTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color foreground = tone.onContainer(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone.container(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: AppSizing.iconXxs, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          // Flexes so a long label wraps inside the pill rather than overflowing it.
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

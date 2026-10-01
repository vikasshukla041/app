import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_sizing.dart';

class PerformanceChartMessage extends StatelessWidget {
  const PerformanceChartMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = actionLabel;

    return Container(
      height: AppSizing.chartHeight,
      width: double.infinity,
      color: colors.surfaceContainer,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          // A button with no label or no action would do nothing, so show it only with both.
          if (label != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(label)),
        ],
      ),
    );
  }
}

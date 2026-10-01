import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/app_tone.dart';
import '../../../core/design_system/widgets/status_dot.dart';

/// display value with current value
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.status,
    required this.tone,
  });

  final String label;
  final String value;
  final String status;
  final AppTone tone;

  static const EdgeInsets _padding = EdgeInsets.all(AppSpacing.lg);

  static EdgeInsetsGeometry _margin(BuildContext context) =>
      CardTheme.of(context).margin ?? EdgeInsets.zero;

  static TextStyle _valueStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = theme.textTheme.bodyMedium!
        .merge(theme.extension<AppFigureText>()!.medium)
        .copyWith(inherit: false);
    return MediaQuery.boldTextOf(context)
        ? style.copyWith(fontWeight: FontWeight.bold)
        : style;
  }

  /// return minimum width needed for value
  double minimumWidth(BuildContext context) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: value, style: _valueStyle(context)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final double width = painter.width.ceilToDouble();
    painter.dispose();
    return width + _padding.horizontal + _margin(context).horizontal;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: _margin(context),
      child: Padding(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _valueStyle(context),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            StatusDot(label: status, tone: tone),
          ],
        ),
      ),
    );
  }
}

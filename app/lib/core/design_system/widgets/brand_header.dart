import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_sizing.dart';
import '../tokens/app_spacing.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: AppSizing.logo,
          height: AppSizing.logo,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Icon(
            Icons.candlestick_chart_outlined,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            AppLocalizations.of(context).appTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }
}

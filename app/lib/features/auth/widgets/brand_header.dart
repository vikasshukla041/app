import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  static const double _logoSize = 40;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _logoSize,
          height: _logoSize,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.candlestick_chart_outlined,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppLocalizations.of(context).appTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

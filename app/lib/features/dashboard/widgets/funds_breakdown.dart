import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/app_tone.dart';
import '../../../core/design_system/widgets/section_header.dart';
import '../../../core/design_system/widgets/spaced_flow.dart';
import '../../../l10n/app_localizations.dart';
import 'stat_card.dart';

class FundsBreakdown extends StatelessWidget {
  const FundsBreakdown({
    super.key,
    required this.availableCash,
    required this.unsettled,
    required this.collateral,
  });

  final String availableCash;
  final String unsettled;
  final String collateral;

  /// The gap between the cards
  static const double _gap = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<StatCard> cards = <StatCard>[
      StatCard(
        label: l10n.fundsAvailableCashLabel,
        value: availableCash,
        status: l10n.fundsAvailableCashStatus,
        tone: AppTone.positive,
      ),
      StatCard(
        label: l10n.fundsUnsettledLabel,
        value: unsettled,
        status: l10n.fundsUnsettledStatus,
        tone: AppTone.pending,
      ),
      StatCard(
        label: l10n.fundsCollateralLabel,
        value: collateral,
        status: l10n.fundsCollateralStatus,
        tone: AppTone.neutral,
      ),
    ];

    final double cardWidth = cards
        .map((StatCard card) => card.minimumWidth(context))
        .reduce(math.max);
    final double abreast = cardWidth * cards.length + _gap * (cards.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: l10n.fundsBreakdownTitle,
          subtitle: l10n.fundsBreakdownSettlement,
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return constraints.maxWidth >= abreast
                ? EqualWidthRow(gap: _gap, children: cards)
                : SpacedColumn(gap: _gap, children: cards);
          },
        ),
      ],
    );
  }
}

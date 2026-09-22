import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../widgets/spaced_flow.dart';
import 'screen_size.dart';

/// Stacks cards on a narrow screen, side by side on a wide one.
class AdaptiveTwoColumn extends StatelessWidget {
  const AdaptiveTwoColumn({
    super.key,
    required this.primary,
    required this.secondary,
  });

  /// The main content — gets the wider column.
  final List<Widget> primary;

  /// Extra cards — sit below [primary] until there is room beside it.
  final List<Widget> secondary;

  // Primary gets 7 parts, secondary gets 5, so primary is wider.
  static const int _primaryFlex = 7;
  static const int _secondaryFlex = 5;

  /// Space between cards and between the two columns.
  static const double _gap = AppSpacing.xl2;

  @override
  Widget build(BuildContext context) {
    if (!ScreenSize.of(context).hasTwoColumns) {
      return SpacedColumn(
        gap: _gap,
        children: <Widget>[...primary, ...secondary],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: _primaryFlex,
          child: SpacedColumn(gap: _gap, children: primary),
        ),
        const SizedBox(width: _gap),
        Expanded(
          flex: _secondaryFlex,
          child: SpacedColumn(gap: _gap, children: secondary),
        ),
      ],
    );
  }
}

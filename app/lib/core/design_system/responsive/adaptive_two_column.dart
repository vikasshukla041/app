import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../widgets/spaced_flow.dart';
import 'app_breakpoints.dart';

/// stack card on small screen n side by side on large
class AdaptiveTwoColumn extends StatelessWidget {
  const AdaptiveTwoColumn({
    super.key,
    required this.primary,
    required this.secondary,
  });

  /// wider column screen.
  final List<Widget> primary;

  /// extra card stay below
  final List<Widget> secondary;

  static const int _primaryFlex = 7;
  static const int _secondaryFlex = 5;
  static const double _gap = AppSpacing.xl2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < AppBreakpoints.twoColumnBody) {
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
      },
    );
  }
}

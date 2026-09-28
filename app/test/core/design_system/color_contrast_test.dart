import 'dart:math' as math;

import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/core/design_system/widgets/app_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 AA, which EN 301 549 requires of financial services sold in the EU.
const double _minimumTextContrast = 4.5;

typedef _Pair = ({String name, Color foreground, Color background});

void main() {
  // Reads the finished themes rather than the raw palette, so nothing slips past.
  for (final ThemeData theme in <ThemeData>[
    ActivoTradeTheme.lightTheme,
    ActivoTradeTheme.darkTheme,
  ]) {
    final ColorScheme colors = theme.colorScheme;
    final AppSemanticColors semantic = theme.extension<AppSemanticColors>()!;

    group('${colors.brightness.name} theme', () {
      for (final _Pair pair in <_Pair>[
        (
          name: 'onPrimary',
          foreground: colors.onPrimary,
          background: colors.primary,
        ),
        (
          name: 'onSecondary',
          foreground: colors.onSecondary,
          background: colors.secondary,
        ),
        (
          name: 'onTertiary',
          foreground: colors.onTertiary,
          background: colors.tertiary,
        ),
        (name: 'onError', foreground: colors.onError, background: colors.error),
        (
          name: 'onPrimaryContainer',
          foreground: colors.onPrimaryContainer,
          background: colors.primaryContainer,
        ),
        (
          name: 'onSecondaryContainer',
          foreground: colors.onSecondaryContainer,
          background: colors.secondaryContainer,
        ),
        (
          name: 'onTertiaryContainer',
          foreground: colors.onTertiaryContainer,
          background: colors.tertiaryContainer,
        ),
        (
          name: 'onErrorContainer',
          foreground: colors.onErrorContainer,
          background: colors.errorContainer,
        ),
        (
          name: 'onSurface over the page',
          foreground: colors.onSurface,
          background: colors.surface,
        ),
        (
          name: 'onSurfaceVariant over the page',
          foreground: colors.onSurfaceVariant,
          background: colors.surface,
        ),
        // Cards, not the page: this is where most of the text the user reads sits.
        (
          name: 'onSurface over a card',
          foreground: colors.onSurface,
          background: colors.surfaceContainerLow,
        ),
        (
          name: 'onSurfaceVariant over a card',
          foreground: colors.onSurfaceVariant,
          background: colors.surfaceContainerLow,
        ),
        (
          name: 'onInverseSurface',
          foreground: colors.onInverseSurface,
          background: colors.inverseSurface,
        ),
        (
          name: 'onWarningContainer',
          foreground: semantic.onWarningContainer,
          background: semantic.warningContainer,
        ),
        (
          name: 'onSuccessContainer',
          foreground: semantic.onSuccessContainer,
          background: semantic.successContainer,
        ),
        (
          name: 'positive over a card',
          foreground: semantic.positive,
          background: colors.surfaceContainerLow,
        ),
      ]) {
        test(pair.name, () {
          final double ratio = _contrastRatio(pair.foreground, pair.background);

          expect(
            ratio,
            greaterThanOrEqualTo(_minimumTextContrast),
            reason:
                '${pair.name} is ${ratio.toStringAsFixed(2)}:1, and AA needs '
                '$_minimumTextContrast:1. Correct the value in app_colors.dart.',
          );
        });
      }

      // A badge picks its colours through AppTone, so the tones are what to check.
      for (final AppTone tone in AppTone.values) {
        testWidgets('${tone.name} badge', (WidgetTester tester) async {
          late Color foreground;
          late Color background;

          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Builder(
                builder: (BuildContext context) {
                  foreground = tone.onContainer(context);
                  background = tone.container(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          );

          final double ratio = _contrastRatio(foreground, background);

          expect(
            ratio,
            greaterThanOrEqualTo(_minimumTextContrast),
            reason:
                'A ${tone.name} badge is ${ratio.toStringAsFixed(2)}:1, and AA '
                'needs $_minimumTextContrast:1. Remap the tone in app_tone.dart.',
          );
        });
      }
    });
  }
}

/// The WCAG ratio, over Flutter's own luminance so the maths cannot drift.
double _contrastRatio(Color foreground, Color background) {
  final double a = foreground.computeLuminance();
  final double b = background.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

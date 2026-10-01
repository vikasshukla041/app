import 'package:flutter/material.dart';

import '../theme.dart';

/// visual tone of UI element
enum AppTone {
  neutral,

  positive,

  pending,

  /// Uses app's brand styling
  brand,

  /// A loss or a drop, in the theme's error colours.
  negative,
}

extension AppToneColours on AppTone {
  Color container(BuildContext context) {
    final ColorScheme colours = Theme.of(context).colorScheme;
    final AppSemanticColors semantic = Theme.of(
      context,
    ).extension<AppSemanticColors>()!;

    return switch (this) {
      AppTone.neutral => colours.secondaryContainer,
      AppTone.positive => semantic.successContainer,
      AppTone.pending => semantic.warningContainer,
      AppTone.brand => colours.primaryContainer,
      AppTone.negative => colours.errorContainer,
    };
  }

  /// Text and icons on container
  Color onContainer(BuildContext context) {
    final ColorScheme colours = Theme.of(context).colorScheme;
    final AppSemanticColors semantic = Theme.of(
      context,
    ).extension<AppSemanticColors>()!;

    return switch (this) {
      AppTone.neutral => colours.onSecondaryContainer,
      AppTone.positive => semantic.onSuccessContainer,
      AppTone.pending => semantic.onWarningContainer,
      AppTone.brand => colours.onPrimaryContainer,
      AppTone.negative => colours.onErrorContainer,
    };
  }

  ///  color for dot or stroke with no container
  Color accent(BuildContext context) {
    final ColorScheme colours = Theme.of(context).colorScheme;
    final AppSemanticColors semantic = Theme.of(
      context,
    ).extension<AppSemanticColors>()!;

    return switch (this) {
      AppTone.neutral => colours.onSurfaceVariant,
      AppTone.positive => semantic.positive,
      AppTone.pending => semantic.warning,
      AppTone.brand => colours.primary,
      AppTone.negative => colours.error,
    };
  }
}

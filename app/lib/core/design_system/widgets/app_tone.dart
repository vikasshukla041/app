import 'package:flutter/material.dart';

import '../theme.dart';

/// What a small piece of UI means, which is the only thing that picks its colour.
enum AppTone {
  /// No opinion — a fact the user does not have to act on.
  neutral,

  /// Settled, enabled, gained.
  positive,

  /// In flight: clearing, awaiting approval, not yours yet.
  pending,

  /// The app itself is speaking, not the data.
  brand,
}

/// Keeps the tone-to-colour mapping in one place instead of in every widget.
extension AppToneColours on AppTone {
  /// The filled background a label sits on.
  Color container(BuildContext context) {
    final ColorScheme colours = Theme.of(context).colorScheme;
    final AppSemanticColors semantic = Theme.of(
      context,
    ).extension<AppSemanticColors>()!;

    return switch (this) {
      // Uses Material's own grey pair; the app has no separate neutral colour.
      AppTone.neutral => colours.secondaryContainer,
      AppTone.positive => semantic.successContainer,
      AppTone.pending => semantic.warningContainer,
      AppTone.brand => colours.primaryContainer,
    };
  }

  /// Text and icons drawn on [container].
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
    };
  }

  /// The colour on its own, for a dot or stroke with no container behind it.
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
    };
  }
}

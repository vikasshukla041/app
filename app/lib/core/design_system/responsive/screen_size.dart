import 'package:flutter/widgets.dart';

import '../tokens/app_spacing.dart';
import 'app_breakpoints.dart';

/// How much room the screen has.
enum ScreenSize {
  /// Phone size — nav bar at the bottom, one column.
  compact,

  /// Small tablet — nav moves to the side, still one column.
  medium,

  /// Big tablet or desktop — side nav, two columns.
  expanded;

  /// Separate from [of] so tests do not need a widget tree.
  static ScreenSize forWidth(double width) {
    if (width >= AppBreakpoints.twoColumn) {
      return ScreenSize.expanded;
    }
    if (width >= AppBreakpoints.sidebar) {
      return ScreenSize.medium;
    }
    return ScreenSize.compact;
  }

  // Uses sizeOf, so this only rebuilds when the screen size changes.
  static ScreenSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// True once nav has moved from the bottom to the side.
  bool get hasSidebar => this != ScreenSize.compact;

  /// True once there is room for a second column.
  bool get hasTwoColumns => this == ScreenSize.expanded;

  /// Side gap for a page's header and its body, so the two line up.
  double get pageGap =>
      pick(compact: AppSpacing.xl, medium: AppSpacing.xl3, expanded: AppSpacing.xl3);

  /// Picks the right value, so a widget never reads pixels itself.
  T pick<T>({required T compact, required T medium, required T expanded}) {
    return switch (this) {
      ScreenSize.compact => compact,
      ScreenSize.medium => medium,
      ScreenSize.expanded => expanded,
    };
  }
}

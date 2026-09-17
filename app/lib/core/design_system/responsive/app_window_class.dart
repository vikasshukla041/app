import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// How much room the window has, named for what the layout does with it.
enum AppWindowClass {
  /// Phone: navigation at the bottom, everything in one column.
  compact,

  /// Small tablet: navigation moves to a sidebar, content stays in one column.
  medium,

  /// Large tablet and desktop: sidebar, and the content splits in two.
  expanded;

  /// Kept apart from [of] so the thresholds can be tested without a widget tree.
  static AppWindowClass forWidth(double width) {
    if (width >= AppBreakpoints.twoColumn) {
      return AppWindowClass.expanded;
    }
    if (width >= AppBreakpoints.sidebar) {
      return AppWindowClass.medium;
    }
    return AppWindowClass.compact;
  }

  /// `sizeOf` rather than `of`, so a caller only rebuilds when the window resizes.
  static AppWindowClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// True once a screen can hold a second column beside its main one.
  bool get hasTwoColumns => this == AppWindowClass.expanded;

  /// One value per class, which is how a widget avoids reading pixels itself.
  T pick<T>({required T compact, required T medium, required T expanded}) {
    return switch (this) {
      AppWindowClass.compact => compact,
      AppWindowClass.medium => medium,
      AppWindowClass.expanded => expanded,
    };
  }
}

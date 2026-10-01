import 'package:flutter/widgets.dart';

import '../tokens/app_spacing.dart';
import 'app_breakpoints.dart';

enum ScreenSize {
  compact,
  medium,
  expanded;

  static ScreenSize forWidth(double width) {
    if (width >= AppBreakpoints.expanded) {
      return ScreenSize.expanded;
    }
    if (width >= AppBreakpoints.sidebar) {
      return ScreenSize.medium;
    }
    return ScreenSize.compact;
  }

  /// `sizeOf` build whn window resizes
  static ScreenSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// true whn navbar moved bottom to side
  bool get hasSidebar => this != ScreenSize.compact;

  /// side gap for page
  double get pageGap => pick(
    compact: AppSpacing.xl,
    medium: AppSpacing.xl3,
    expanded: AppSpacing.xl3,
  );

  /// one value per card, no pixel
  T pick<T>({required T compact, required T medium, required T expanded}) {
    return switch (this) {
      ScreenSize.compact => compact,
      ScreenSize.medium => medium,
      ScreenSize.expanded => expanded,
    };
  }
}

/// The widths where the layout changes, each named after what changes there.
abstract final class AppBreakpoints {
  /// Below this the navigation sits at the bottom of the screen; above it, down the side.
  static const double sidebar = 768;

  /// A window this wide counts as a big tablet or desktop.
  static const double expanded = 1024;

  /// The page body, not the window, needs this much room for two columns.
  ///
  /// It is the body width the two-column console was approved at: a 1024px
  /// window beside the old 80px menu and its 1px divider, less the page's
  /// 32px side gaps: 1024 − 80 − 1 − 64.
  static const double twoColumnBody = 879;
}

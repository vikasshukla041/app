/// The widths where the layout changes, each named after what changes there.
abstract final class AppBreakpoints {
  /// Below this the navigation sits at the bottom of the screen; above it, down the side.
  static const double sidebar = 768;

  /// Above this there is room for the console's second column.
  static const double twoColumn = 1024;
}

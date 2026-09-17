/// Opacities applied to a theme colour, so a tint is never a loose number.
abstract final class AppOpacity {
  /// A colour washed back far enough to sit behind its own icon or label.
  static const double tint = 0.12;

  /// A container softened but still readable, as on the notification dialog.
  static const double wash = 0.5;
}

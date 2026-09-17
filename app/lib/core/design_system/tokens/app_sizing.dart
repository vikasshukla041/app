/// Fixed sizes that are neither spacing nor radius: icons, spinners, limits.
abstract final class AppSizing {
  // Icon sizes. iconXs is a one-off, not part of the regular scale below.
  static const double iconXxs = 16;
  static const double iconXs = 22;
  static const double iconSm = 36;
  static const double iconMd = 64;
  static const double iconLg = 72;

  /// Progress indicators; the larger fills a button the smaller leaves empty.
  static const double spinnerSm = 20;
  static const double spinnerMd = 24;

  /// The brand logo tile on the auth screens.
  static const double logo = 40;

  /// Reserved for the performance curve, so the card keeps its height either way.
  static const double chartHeight = 160;

  /// Caps an auth screen so a tablet does not stretch the form across the width.
  static const double maxContentWidth = 420;

  /// The same idea for a data screen, where the cards need far more room.
  static const double maxConsoleWidth = 1152;
}

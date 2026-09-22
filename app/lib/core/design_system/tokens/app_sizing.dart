/// Sizes that are not spacing or radius — icons, spinners, limits.
abstract final class AppSizing {
  // Icon sizes. iconXs does not fit the scale below.
  static const double iconXxs = 16;
  static const double iconXs = 22;
  static const double iconSm = 36;
  static const double iconMd = 64;
  static const double iconLg = 72;

  /// Loading spinners — the big one fills a button, the small one does not.
  static const double spinnerSm = 20;
  static const double spinnerMd = 24;

  /// The brand logo tile on the auth screens.
  static const double logo = 40;

  /// The avatar size in the app bar.
  static const double avatar = 32;

  /// Height for the performance chart, so the card stays the same size either way.
  static const double chartHeight = 160;

  /// Stops the login form from stretching too wide on a tablet.
  static const double maxContentWidth = 420;

  /// Same idea, but for a data screen with bigger cards.
  static const double maxConsoleWidth = 1152;
}

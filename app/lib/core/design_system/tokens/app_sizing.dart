/// Fixed sizes that are neither spacing nor radius: icons, spinners, and the
/// couple of layout limits the screens share.
///
/// These lived as private `static const` fields inside individual widgets,
/// which meant `_spinnerSize = 20` existed in two files and `_maxContentWidth
/// = 420` in three. Same value, three chances to drift.
abstract final class AppSizing {
  /// Icon sizes, smallest to largest.
  ///
  /// [iconXs] (22) breaks the pattern — it is the quick-links tile icon and
  /// sits between two steps. Worth snapping once design confirms.
  static const double iconXxs = 16;
  static const double iconXs = 22;
  static const double iconSm = 36;
  static const double iconMd = 64;
  static const double iconLg = 72;

  /// Progress indicators. The larger one sits inside a filled button, where a
  /// 20 would leave the button looking empty.
  static const double spinnerSm = 20;
  static const double spinnerMd = 24;

  /// The brand logo tile on the auth screens.
  static const double logo = 40;

  /// Minimum tap target for a primary action; matches the button themes.
  static const double buttonHeight = 48;

  /// Auth screens are centred and capped so a tablet does not stretch a login
  /// form across the whole width.
  static const double maxContentWidth = 420;
}

/// The spacing scale.
///
/// Every value here is a multiple of 4 and every one of them is already used
/// by a screen today — this file names what the app does, it does not change
/// it. Adopting it is a refactor with no visual difference.
///
/// Nine steps is more than a scale should have. [xl] (20) and [xl4] (40) are
/// the two to fold away once design signs off; they appear five and two times
/// respectively and both sit next to a neighbour that would do.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 24;
  static const double xl3 = 32;
  static const double xl4 = 40;
  static const double xl5 = 48;
}

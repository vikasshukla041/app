/// Corner radii.
///
/// Same rule as [AppSpacing]: these are the values already on screen, named.
///
/// [xs] (10) is the odd one out — it is used once, on the brand logo tile, and
/// breaks the 4-step pattern the others follow. Fold it into [sm] when someone
/// can confirm the logo still looks right.
abstract final class AppRadius {
  static const double xs = 10;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
}

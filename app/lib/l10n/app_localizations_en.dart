// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ActivoTrade';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to your investment account';

  @override
  String get usernameLabel => 'Username or email';

  @override
  String get usernameFieldSemantics => 'Username or email input field';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordFieldSemantics => 'Password input field';

  @override
  String get signInButton => 'Log In';

  @override
  String get signInButtonSemantics => 'Log in button';

  @override
  String get useBiometrics => 'Use Biometrics';

  @override
  String get useBiometricsSemantics => 'Log in with biometrics button';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String dashboardWelcome(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get errorNetwork =>
      'Unable to connect to server.\nPlease check your network connection.';

  @override
  String get errorCredentials => 'Invalid username or password.';

  @override
  String get errorTooManyAttempts =>
      'Too many login attempts. Please try again later.';

  @override
  String get errorServerUnavailable =>
      'Server is currently unavailable. Please try again later.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again later.';

  @override
  String get biometricOptIn => 'Enable biometric login';

  @override
  String get biometricPromptReason => 'Authenticate to sign in to ActivoTrade';

  @override
  String get errorBiometricLockedOut =>
      'Too many failed attempts. Use your password to sign in.';

  @override
  String get errorBiometricSessionExpired =>
      'Your saved session is no longer valid. Please sign in with your password.';

  @override
  String get dashboardWelcomeLabel => 'Welcome back,';

  @override
  String get signOutTooltip => 'Sign out';

  @override
  String get biometricOptInDialogTitle => 'Enable Biometric Login?';

  @override
  String get biometricOptInDialogBody =>
      'Would you like to enable Face ID / Touch ID to sign in faster on your next visit?';

  @override
  String get biometricOptInDialogSkip => 'Skip for Now';

  @override
  String get biometricOptInDialogEnable => 'Enable Biometrics';

  @override
  String get portfolioTotalValueLabel => 'Total Portfolio Value';

  @override
  String get portfolioTotalGainLabel => 'Total Gain';

  @override
  String get quickLinksHeader => 'Account Navigation';

  @override
  String get quickLinkHoldingsTitle => 'Holdings';

  @override
  String get quickLinkHoldingsSubtitle =>
      'View active asset allocation & portfolio breakdown';

  @override
  String get quickLinkPositionsTitle => 'Positions';

  @override
  String get quickLinkPositionsSubtitle =>
      'Live equity & open market positions';

  @override
  String get quickLinkOrdersTitle => 'Orders';

  @override
  String get quickLinkOrdersSubtitle =>
      'Pending, executed, and cancelled trade orders';

  @override
  String get quickLinkReportsTitle => 'Reports';

  @override
  String get quickLinkReportsSubtitle =>
      'Account tax reports & activity summaries';

  @override
  String get quickLinkPnlTitle => 'P&L Statement';

  @override
  String get quickLinkPnlSubtitle =>
      'Realized & unrealized profit/loss breakdown';

  @override
  String quickLinkSelectedMessage(String title) {
    return '$title selected';
  }

  @override
  String get dashboardLoadError => 'Couldn\'t load your portfolio.';

  @override
  String get retry => 'Retry';

  @override
  String get signOutSemantics => 'Sign out button';

  @override
  String get signOutAndUseAnotherAccount => 'Sign out and use another account';
}

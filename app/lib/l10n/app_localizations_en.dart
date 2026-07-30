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
  String get dashboardWelcome => 'Welcome to ActivoTrade';

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
}

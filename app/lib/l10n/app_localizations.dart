import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ActivoTrade'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your investment account'**
  String get loginSubtitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get usernameLabel;

  /// No description provided for @usernameFieldSemantics.
  ///
  /// In en, this message translates to:
  /// **'Username or email input field'**
  String get usernameFieldSemantics;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordFieldSemantics.
  ///
  /// In en, this message translates to:
  /// **'Password input field'**
  String get passwordFieldSemantics;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get signInButton;

  /// No description provided for @signInButtonSemantics.
  ///
  /// In en, this message translates to:
  /// **'Log in button'**
  String get signInButtonSemantics;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get useBiometrics;

  /// No description provided for @useBiometricsSemantics.
  ///
  /// In en, this message translates to:
  /// **'Log in with biometrics button'**
  String get useBiometricsSemantics;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String dashboardWelcome(String name);

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to server.\nPlease check your network connection.'**
  String get errorNetwork;

  /// No description provided for @errorCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get errorCredentials;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many login attempts. Please try again later.'**
  String get errorTooManyAttempts;

  /// No description provided for @errorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server is currently unavailable. Please try again later.'**
  String get errorServerUnavailable;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again later.'**
  String get errorGeneric;

  /// No description provided for @biometricOptIn.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric login'**
  String get biometricOptIn;

  /// No description provided for @biometricPromptReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to sign in to ActivoTrade'**
  String get biometricPromptReason;

  /// No description provided for @errorBiometricLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Use your password to sign in.'**
  String get errorBiometricLockedOut;

  /// No description provided for @errorBiometricSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your saved session is no longer valid. Please sign in with your password.'**
  String get errorBiometricSessionExpired;

  /// No description provided for @dashboardWelcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get dashboardWelcomeLabel;

  /// No description provided for @signOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutTooltip;

  /// No description provided for @biometricOptInDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Login?'**
  String get biometricOptInDialogTitle;

  /// No description provided for @biometricOptInDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to enable Face ID / Touch ID to sign in faster on your next visit?'**
  String get biometricOptInDialogBody;

  /// No description provided for @biometricOptInDialogSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get biometricOptInDialogSkip;

  /// No description provided for @biometricOptInDialogEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometrics'**
  String get biometricOptInDialogEnable;

  /// No description provided for @portfolioTotalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Portfolio Value'**
  String get portfolioTotalValueLabel;

  /// No description provided for @portfolioTotalGainLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Gain'**
  String get portfolioTotalGainLabel;

  /// No description provided for @quickLinksHeader.
  ///
  /// In en, this message translates to:
  /// **'Account Navigation'**
  String get quickLinksHeader;

  /// No description provided for @quickLinkHoldingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get quickLinkHoldingsTitle;

  /// No description provided for @quickLinkHoldingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View active asset allocation & portfolio breakdown'**
  String get quickLinkHoldingsSubtitle;

  /// No description provided for @quickLinkPositionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get quickLinkPositionsTitle;

  /// No description provided for @quickLinkPositionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live equity & open market positions'**
  String get quickLinkPositionsSubtitle;

  /// No description provided for @quickLinkOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get quickLinkOrdersTitle;

  /// No description provided for @quickLinkOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending, executed, and cancelled trade orders'**
  String get quickLinkOrdersSubtitle;

  /// No description provided for @quickLinkReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get quickLinkReportsTitle;

  /// No description provided for @quickLinkReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Account tax reports & activity summaries'**
  String get quickLinkReportsSubtitle;

  /// No description provided for @quickLinkPnlTitle.
  ///
  /// In en, this message translates to:
  /// **'P&L Statement'**
  String get quickLinkPnlTitle;

  /// No description provided for @quickLinkPnlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Realized & unrealized profit/loss breakdown'**
  String get quickLinkPnlSubtitle;

  /// No description provided for @quickLinkSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} selected'**
  String quickLinkSelectedMessage(String title);

  /// No description provided for @dashboardLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your portfolio.'**
  String get dashboardLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @signOutSemantics.
  ///
  /// In en, this message translates to:
  /// **'Sign out button'**
  String get signOutSemantics;

  /// No description provided for @signOutAndUseAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out and use another account'**
  String get signOutAndUseAnotherAccount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

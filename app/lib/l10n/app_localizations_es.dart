// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ActivoTrade';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get loginSubtitle => 'Inicia sesión en tu cuenta de inversión';

  @override
  String get usernameLabel => 'Usuario o correo electrónico';

  @override
  String get usernameFieldSemantics => 'Campo de usuario o correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordFieldSemantics => 'Campo de contraseña';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get signInButtonSemantics => 'Botón de iniciar sesión';

  @override
  String get useBiometrics => 'Usar biometría';

  @override
  String get useBiometricsSemantics =>
      'Botón de inicio de sesión con biometría';

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get dashboardWelcome => 'Bienvenido a ActivoTrade';

  @override
  String get errorNetwork =>
      'No se pudo conectar con el servidor.\nComprueba tu conexión a internet.';

  @override
  String get errorCredentials => 'Nombre de usuario o contraseña incorrectos.';

  @override
  String get errorTooManyAttempts =>
      'Demasiados intentos de inicio de sesión. Inténtalo más tarde.';

  @override
  String get errorServerUnavailable =>
      'El servidor no está disponible en este momento. Inténtalo más tarde.';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo más tarde.';
}

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
  String get usernameLabel => 'Nombre de usuario o correo electrónico';

  @override
  String get usernameFieldSemantics =>
      'Campo de entrada de nombre de usuario o correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordFieldSemantics => 'Campo de entrada de contraseña';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get signInButtonSemantics => 'Botón de iniciar sesión';

  @override
  String get useBiometrics => 'Usar biometría';

  @override
  String get useBiometricsSemantics =>
      'Botón para iniciar sesión con biometría';

  @override
  String get dashboardTitle => 'Panel de control';

  @override
  String dashboardWelcome(String name) {
    return 'Bienvenido de nuevo, $name';
  }

  @override
  String get errorNetwork =>
      'No se puede conectar al servidor.\nPor favor, verifica tu conexión a Internet.';

  @override
  String get errorCredentials => 'Nombre de usuario o contraseña no válidos.';

  @override
  String get errorTooManyAttempts =>
      'Demasiados intentos de inicio de sesión. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get errorServerUnavailable =>
      'El servidor no está disponible actualmente. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get errorGeneric =>
      'Algo salió mal. Por favor, inténtalo de nuevo más tarde.';

  @override
  String get biometricOptIn => 'Habilitar inicio de sesión biométrico';

  @override
  String get biometricPromptReason =>
      'Autentícate para iniciar sesión en ActivoTrade';

  @override
  String get errorBiometricLockedOut =>
      'Demasiados intentos fallidos. Usa tu contraseña para iniciar sesión.';

  @override
  String get errorBiometricSessionExpired =>
      'Tu sesión guardada ya no es válida. Por favor, inicia sesión con tu contraseña.';

  @override
  String get dashboardWelcomeLabel => 'Bienvenido de nuevo,';

  @override
  String get signOutTooltip => 'Cerrar sesión';

  @override
  String get biometricOptInDialogTitle =>
      '¿Habilitar inicio de sesión biométrico?';

  @override
  String get biometricOptInDialogBody =>
      '¿Deseas habilitar Face ID / Touch ID para iniciar sesión más rápido en tu próxima visita?';

  @override
  String get biometricOptInDialogSkip => 'Omitir por ahora';

  @override
  String get biometricOptInDialogEnable => 'Habilitar biometría';

  @override
  String get portfolioTotalValueLabel => 'Valor total de la cartera';

  @override
  String get portfolioTotalGainLabel => 'Ganancia total';

  @override
  String get quickLinksHeader => 'Navegación de la cuenta';

  @override
  String get quickLinkHoldingsTitle => 'Participaciones';

  @override
  String get quickLinkHoldingsSubtitle =>
      'Ver asignación de activos y desglose de la cartera';

  @override
  String get quickLinkPositionsTitle => 'Posiciones';

  @override
  String get quickLinkPositionsSubtitle =>
      'Posiciones abiertas y de renta variable en tiempo real';

  @override
  String get quickLinkOrdersTitle => 'Órdenes';

  @override
  String get quickLinkOrdersSubtitle =>
      'Órdenes de compra y venta pendientes, ejecutadas y canceladas';

  @override
  String get quickLinkReportsTitle => 'Informes';

  @override
  String get quickLinkReportsSubtitle =>
      'Informes fiscales de la cuenta y resúmenes de actividad';

  @override
  String get quickLinkPnlTitle => 'Estado de pérdidas y ganancias';

  @override
  String get quickLinkPnlSubtitle =>
      'Desglose de ganancias y pérdidas realizadas y no realizadas';

  @override
  String quickLinkSelectedMessage(String title) {
    return '$title seleccionado';
  }

  @override
  String get dashboardLoadError => 'No se pudo cargar tu cartera.';

  @override
  String get retry => 'Reintentar';

  @override
  String get signOutSemantics => 'Botón de cerrar sesión';

  @override
  String get signOutAndUseAnotherAccount => 'Cerrar sesión y usar otra cuenta';
}

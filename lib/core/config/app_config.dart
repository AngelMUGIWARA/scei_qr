/// Configuración global de la app (arquitectura-login-sesion §3).
///
/// El [apiBaseUrl] se inyecta en tiempo de compilación:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000/api/v1
///
/// Por defecto apunta a localhost (emulador iOS / escritorio).
class AppConfig {
  AppConfig._();

  /// Base de la API (NestJS, global prefix `api/v1`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Timeout de las peticiones HTTP.
  static const Duration requestTimeout = Duration(seconds: 15);
}

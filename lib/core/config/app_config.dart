import '../errors/app_exception.dart';

/// Configuración global de la app (arquitectura-login-sesion §3).
///
/// El [apiBaseUrl] se inyecta en tiempo de compilación:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000/api/v1
///
/// Por defecto apunta a localhost (emulador iOS / escritorio).
class AppConfig {
  AppConfig._();

  static const Set<String> _allowedHttpHosts = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };

  /// Base de la API (NestJS, global prefix `api/v1`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Timeout de las peticiones HTTP.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Valida la URL base de la API según la política de seguridad.
  ///
  /// - Acepta HTTPS para cualquier host válido.
  /// - Acepta HTTP únicamente para localhost, 127.0.0.1 y 10.0.2.2.
  /// - Rechaza HTTP remoto y cualquier otro protocolo.
  static void validateBaseUrl(String baseUrl) {
    late final Uri uri;

    try {
      uri = Uri.parse(baseUrl);
    } on FormatException {
      throw const ConfigException();
    }

    if (!uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
      throw const ConfigException();
    }

    if (uri.userInfo.isNotEmpty) {
      throw const ConfigException();
    }

    if (uri.fragment.isNotEmpty) {
      throw const ConfigException();
    }

    if (uri.hasPort) {
      final port = uri.port;
      if (port < 1 || port > 65535) {
        throw const ConfigException();
      }
    }

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (scheme == 'https') {
      return;
    }

    if (scheme == 'http') {
      if (_allowedHttpHosts.contains(host)) {
        return;
      }
      throw const ConfigException();
    }

    throw const ConfigException();
  }
}

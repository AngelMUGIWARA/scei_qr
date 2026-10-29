/// Errores tipados del dominio (arquitectura-login-sesion §4).
///
/// La UI nunca muestra mensajes crudos de la API: se traducen a estos
/// tipos para conservar el mensaje **genérico** exigido por HU-AL-01.
abstract class AppException implements Exception {
  const AppException(this.message);

  /// Mensaje seguro para mostrar al usuario.
  final String message;

  @override
  String toString() => message;
}

/// 401/400 de autenticación y validaciones de credenciales.
///
/// CA HU-AL-01: nunca revela si falló el usuario o la contraseña.
class AuthException extends AppException {
  const AuthException([
    super.message = 'Usuario o contraseña incorrectos',
  ]);
}

/// Sin conectividad, DNS o timeout.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No se pudo conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
  ]);
}

/// 5xx o respuesta malformada.
class ServerException extends AppException {
  const ServerException([
    super.message = 'Error del servidor. Inténtalo más tarde.',
  ]);
}

/// Campos vacíos o inválidos (validación local antes de enviar).
class ValidationException extends AppException {
  const ValidationException([
    super.message = 'Completa los campos requeridos.',
  ]);
}

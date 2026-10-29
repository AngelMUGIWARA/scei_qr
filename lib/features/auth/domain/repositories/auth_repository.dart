import '../../../../dominio/sesion.dart';

/// Contrato de autenticación (arquitectura-login-sesion §2, patrón Repository).
///
/// Único punto de verdad de la sesión: la implementación decide si habla con
/// la API real o con un mock, sin que el Dominio ni la UI lo noten.
///
/// Devuelve [Sesion], la entidad de `lib/dominio/sesion.dart` compartida con
/// el guard de acceso (HU-GEN-01).
abstract class AuthRepository {
  /// Autentica contra `POST /auth/login`.
  ///
  /// Lanza [AuthException] con mensaje genérico si las credenciales son
  /// inválidas o la cuenta está inactiva (CA HU-AL-01).
  Future<Sesion> login(String username, String password);

  /// Recupera la sesión persistida; `null` si no existe o el JWT expiró.
  Future<Sesion?> restoreSession();
}

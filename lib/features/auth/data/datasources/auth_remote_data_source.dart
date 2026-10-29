import '../models/auth_response_model.dart';

/// Fuente de datos remota de autenticación (arquitectura-login-sesion §4).
///
/// Interfaz con una implementación HTTP real; el repositorio no conoce el
/// transporte, lo que permite sustituirla por un mock en tests.
abstract class AuthRemoteDataSource {
  /// `POST {baseUrl}/auth/login`.
  ///
  /// Lanza [AuthException] ante 400/401, [NetworkException] ante fallo de red
  /// o timeout y [ServerException] ante 5xx/respuesta inválida.
  Future<AuthResponseModel> login(String username, String password);
}

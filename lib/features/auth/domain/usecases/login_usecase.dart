import '../../../../dominio/sesion.dart';
import '../../../../core/errors/app_exception.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: iniciar sesión (HU-AL-01, HU-ST-01, HU-AD-01).
///
/// Una sola responsabilidad: validar la entrada y delegar en el Repositorio.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Sesion> call(String username, String password) async {
    final user = username.trim();

    if (user.isEmpty || password.isEmpty) {
      throw const ValidationException('Completa usuario y contraseña.');
    }

    if (password.length < 6) {
      // El DTO del backend exige MinLength(6): se valida igual en cliente
      // para no disparar un 400 que rompería el mensaje genérico.
      throw const AuthException();
    }

    return _repository.login(user, password);
  }
}

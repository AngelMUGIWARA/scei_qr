import '../../../../dominio/sesion.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: restaurar la sesión al abrir la app (HU-AL-01, sesión persistente).
class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  /// Devuelve la sesión guardada o `null` si no hay token o ya expiró.
  Future<Sesion?> call() => _repository.restoreSession();
}

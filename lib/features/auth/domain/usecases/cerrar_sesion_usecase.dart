import '../repositories/auth_repository.dart';

/// Cierra la sesión local del usuario (HU-GEN-02).
///
/// Borra el token y los datos de sesión del almacenamiento seguro. El JWT es
/// stateless: el backend no lo revoca, por eso el cierre es local y las rutas
/// protegidas dejan de ser accesibles en cuanto la UI observa sesión `null`.
class CerrarSesionUseCase {
  const CerrarSesionUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.cerrarSesion();
}

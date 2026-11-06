import '../../../../dominio/tecnico.dart';
import '../repositories/usuarios_repository.dart';

/// Activa o desactiva una cuenta de técnico (baja lógica, HU-AD-03).
class CambiarEstadoTecnicoUseCase {
  const CambiarEstadoTecnicoUseCase(this._repository);

  final UsuariosRepository _repository;

  Future<Tecnico> call(int id, {required bool activo}) {
    return _repository.cambiarEstadoTecnico(id, activo: activo);
  }
}

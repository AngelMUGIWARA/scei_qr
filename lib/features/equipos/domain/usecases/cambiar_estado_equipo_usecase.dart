import '../../../../dominio/equipo.dart';
import '../repositories/equipos_repository.dart';

class CambiarEstadoEquipoUseCase {
  const CambiarEstadoEquipoUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Equipo> call(int id, {required bool activo}) {
    return _repository.cambiarEstadoEquipo(id, activo: activo);
  }
}

import '../../../../dominio/equipo.dart';
import '../repositories/equipos_repository.dart';

class ObtenerEquipoUseCase {
  const ObtenerEquipoUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Equipo> call(int id) => _repository.obtenerEquipoPorId(id);
}

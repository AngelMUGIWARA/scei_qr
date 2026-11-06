import '../../../../dominio/equipo.dart';
import '../repositories/equipos_repository.dart';

class ListarEquiposUseCase {
  const ListarEquiposUseCase(this._repository);

  final EquiposRepository _repository;

  Future<List<Equipo>> call({String? q, String? ubicacion, bool? activo}) {
    return _repository.listarEquipos(
      q: q,
      ubicacion: ubicacion,
      activo: activo,
    );
  }
}

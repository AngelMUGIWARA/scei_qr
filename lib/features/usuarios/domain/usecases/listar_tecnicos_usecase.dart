import '../../../../dominio/tecnico.dart';
import '../repositories/usuarios_repository.dart';

/// Lista los técnicos de soporte, opcionalmente filtrados por nombre
/// (HU-AD-03).
class ListarTecnicosUseCase {
  const ListarTecnicosUseCase(this._repository);

  final UsuariosRepository _repository;

  Future<List<Tecnico>> call({String? busqueda, bool? activo}) {
    final limpio = busqueda?.trim();
    return _repository.listarTecnicos(
      busqueda: limpio == null || limpio.isEmpty ? null : limpio,
      activo: activo,
    );
  }
}

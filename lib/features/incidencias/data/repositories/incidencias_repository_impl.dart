import '../../../../dominio/incidencia.dart';
import '../../../../dominio/nueva_incidencia.dart';
import '../../domain/repositories/incidencias_repository.dart';
import '../datasources/incidencias_remote_data_source.dart';

class IncidenciasRepositoryImpl implements IncidenciasRepository {
  const IncidenciasRepositoryImpl(this._remote);

  final IncidenciasRemoteDataSource _remote;

  @override
  Future<Incidencia> reportarIncidencia(NuevaIncidencia datos) async {
    final model = await _remote.reportarIncidencia(
      equipoId: datos.equipoId,
      tipo: datos.tipo,
      descripcion: datos.descripcion,
    );
    return model.toEntity();
  }
}

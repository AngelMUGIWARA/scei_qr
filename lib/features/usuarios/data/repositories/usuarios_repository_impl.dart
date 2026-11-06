import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/edicion_tecnico.dart';
import '../../../../dominio/tecnico.dart';
import '../../domain/repositories/usuarios_repository.dart';
import '../datasources/usuarios_remote_data_source.dart';

class UsuariosRepositoryImpl implements UsuariosRepository {
  const UsuariosRepositoryImpl(this.remote);

  final UsuariosRemoteDataSource remote;

  @override
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud) async {
    final model = await remote.registrarTecnico(solicitud);
    return model.toEntity();
  }

  @override
  Future<List<Tecnico>> listarTecnicos({String? busqueda, bool? activo}) async {
    final models = await remote.listarTecnicos(
      busqueda: busqueda,
      activo: activo,
    );
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<Tecnico> editarTecnico(
    int id,
    SolicitudEdicionTecnico solicitud,
  ) async {
    final model = await remote.editarTecnico(id, solicitud);
    return model.toEntity();
  }

  @override
  Future<Tecnico> cambiarEstadoTecnico(int id, {required bool activo}) async {
    final model = await remote.cambiarEstadoTecnico(id, activo: activo);
    return model.toEntity();
  }
}

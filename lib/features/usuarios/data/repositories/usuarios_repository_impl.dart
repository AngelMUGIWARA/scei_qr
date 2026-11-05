import '../../../../dominio/alta_tecnico.dart';
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
}

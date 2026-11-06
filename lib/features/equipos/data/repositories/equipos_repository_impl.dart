import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/repositories/equipos_repository.dart';
import '../datasources/equipos_remote_data_source.dart';

class EquiposRepositoryImpl implements EquiposRepository {
  const EquiposRepositoryImpl(this.remote);

  final EquiposRemoteDataSource remote;

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    final model = await remote.registrarEquipo(solicitud);
    return model.toEntity();
  }
}

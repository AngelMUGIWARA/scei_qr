import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/edicion_equipo.dart';
import '../models/equipo_model.dart';

abstract class EquiposRemoteDataSource {
  Future<EquipoModel> registrarEquipo(SolicitudAltaEquipo solicitud);

  Future<List<EquipoModel>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  });

  Future<EquipoModel> obtenerEquipoPorId(int id);

  Future<EquipoModel> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  );

  Future<EquipoModel> cambiarEstadoEquipo(int id, {required bool activo});
}

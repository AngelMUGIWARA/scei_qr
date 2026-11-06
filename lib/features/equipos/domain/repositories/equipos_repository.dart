import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/edicion_equipo.dart';
import '../../../../dominio/equipo.dart';

abstract class EquiposRepository {
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud);

  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  });

  Future<Equipo> obtenerEquipoPorId(int id);

  Future<Equipo> actualizarEquipo(int id, SolicitudEdicionEquipo solicitud);

  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo});
}

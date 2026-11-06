import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/edicion_tecnico.dart';
import '../../../../dominio/tecnico.dart';

abstract class UsuariosRepository {
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud);

  Future<List<Tecnico>> listarTecnicos({String? busqueda, bool? activo});

  Future<Tecnico> editarTecnico(int id, SolicitudEdicionTecnico solicitud);

  Future<Tecnico> cambiarEstadoTecnico(int id, {required bool activo});
}

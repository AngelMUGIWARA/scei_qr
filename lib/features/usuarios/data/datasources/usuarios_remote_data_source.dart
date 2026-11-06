import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/edicion_tecnico.dart';
import '../models/tecnico_model.dart';

abstract class UsuariosRemoteDataSource {
  Future<TecnicoModel> registrarTecnico(SolicitudAltaTecnico solicitud);

  Future<List<TecnicoModel>> listarTecnicos({String? busqueda, bool? activo});

  Future<TecnicoModel> editarTecnico(int id, SolicitudEdicionTecnico solicitud);

  Future<TecnicoModel> cambiarEstadoTecnico(int id, {required bool activo});
}

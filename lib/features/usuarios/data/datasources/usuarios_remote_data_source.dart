import '../../../../dominio/alta_tecnico.dart';
import '../models/tecnico_model.dart';

abstract class UsuariosRemoteDataSource {
  Future<TecnicoModel> registrarTecnico(SolicitudAltaTecnico solicitud);
}

import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/tecnico.dart';

abstract class UsuariosRepository {
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud);
}

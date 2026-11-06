import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/edicion_tecnico.dart';
import '../../../../dominio/tecnico.dart';
import '../repositories/usuarios_repository.dart';

/// Edita los datos de contacto y, opcionalmente, restablece la contraseña
/// de un técnico (HU-AD-03).
class EditarTecnicoUseCase {
  const EditarTecnicoUseCase(this._repository);

  final UsuariosRepository _repository;

  Future<Tecnico> call(int id, SolicitudEdicionTecnico solicitud) async {
    final errores = solicitud.errores;
    if (errores.isNotEmpty) {
      throw ValidationException(errores.first);
    }
    return _repository.editarTecnico(id, solicitud);
  }
}

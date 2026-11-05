import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/tecnico.dart';
import '../repositories/usuarios_repository.dart';

class RegistrarTecnicoUseCase {
  const RegistrarTecnicoUseCase(this._repository);

  final UsuariosRepository _repository;

  Future<Tecnico> call(SolicitudAltaTecnico solicitud) async {
    final errores = solicitud.errores;
    if (errores.isNotEmpty) {
      throw ValidationException(errores.first);
    }
    return _repository.registrarTecnico(solicitud);
  }
}

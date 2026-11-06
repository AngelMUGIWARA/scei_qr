import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/edicion_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../repositories/equipos_repository.dart';

class ActualizarEquipoUseCase {
  const ActualizarEquipoUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Equipo> call(int id, SolicitudEdicionEquipo solicitud) {
    final errores = solicitud.errores;
    if (errores.isNotEmpty) {
      throw ValidationException(errores.first);
    }
    return _repository.actualizarEquipo(id, solicitud);
  }
}

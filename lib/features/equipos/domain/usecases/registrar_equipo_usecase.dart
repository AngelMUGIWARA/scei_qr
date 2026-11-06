import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../repositories/equipos_repository.dart';

class RegistrarEquipoUseCase {
  const RegistrarEquipoUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Equipo> call(SolicitudAltaEquipo solicitud) async {
    final errores = solicitud.errores;
    if (errores.isNotEmpty) {
      throw ValidationException(errores.first);
    }
    return _repository.registrarEquipo(solicitud);
  }
}

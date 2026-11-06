import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_alumno.dart';
import '../../../../dominio/alumno.dart';
import '../repositories/alumnos_repository.dart';

class RegistrarAlumnoUseCase {
  const RegistrarAlumnoUseCase(this._repository);

  final AlumnosRepository _repository;

  Future<Alumno> call(SolicitudAltaAlumno solicitud) async {
    final errores = solicitud.errores;
    if (errores.isNotEmpty) {
      throw ValidationException(errores.first);
    }
    return _repository.registrarAlumno(solicitud);
  }
}

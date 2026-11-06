import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alumno.dart';
import '../repositories/alumnos_repository.dart';

/// Baja lógica y reactivación de una cuenta de alumno (HU-AD-12).
///
/// CA: "Se puede desactivar una cuenta conservando su historial". La
/// operación solo cambia `activo`; el registro y sus usos nunca se borran.
class CambiarEstadoAlumnoUseCase {
  const CambiarEstadoAlumnoUseCase(this._repository);

  final AlumnosRepository _repository;

  /// [activo] `false` da de baja, `true` reactiva.
  Future<Alumno> call(Alumno alumno, {required bool activo}) async {
    final id = alumno.id;
    if (id == null) {
      throw const ValidationException(
        'La cuenta todavía no tiene identificador en el servidor.',
      );
    }
    return _repository.cambiarEstado(id: id, activo: activo);
  }
}

import '../../../../dominio/alta_alumno.dart';
import '../../../../dominio/alumno.dart';

abstract class AlumnosRepository {
  /// Alta de una cuenta de alumno por captura individual (HU-AD-12).
  Future<Alumno> registrarAlumno(SolicitudAltaAlumno solicitud);

  /// Listado de cuentas de alumno con búsqueda opcional (HU-AD-12).
  ///
  /// Incluye las cuentas desactivadas: conservarlas en la lista es parte del
  /// criterio "Se puede desactivar una cuenta conservando su historial".
  Future<List<Alumno>> listarAlumnos({String? busqueda, bool? activo});

  /// Baja lógica (`activo: false`) o reactivación (`activo: true`) de una
  /// cuenta existente. Nunca elimina el registro (HU-AD-12).
  Future<Alumno> cambiarEstado({required int id, required bool activo});
}

import '../../../../dominio/alumno.dart';
import '../repositories/alumnos_repository.dart';

/// Listado de cuentas de alumno para la pantalla de gestión (HU-AD-12).
///
/// Sin filtros obligatorios: el criterio es ver todas las cuentas — activas y
/// dadas de baja — para poder desactivar y reactivar conservando el historial.
class ListarAlumnosUseCase {
  const ListarAlumnosUseCase(this._repository);

  final AlumnosRepository _repository;

  Future<List<Alumno>> call({String? busqueda, bool? activo}) {
    return _repository.listarAlumnos(busqueda: busqueda, activo: activo);
  }
}

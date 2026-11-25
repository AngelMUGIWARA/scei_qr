import '../../../../dominio/incidencia.dart';
import '../../../../dominio/nueva_incidencia.dart';

/// Contrato de repositorio para incidencias (HU-AL-06).
abstract class IncidenciasRepository {
  /// Crea una incidencia y devuelve la entidad con folio asignado.
  Future<Incidencia> reportarIncidencia(NuevaIncidencia datos);
}

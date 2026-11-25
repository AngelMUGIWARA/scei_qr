import '../models/incidencia_model.dart';
import '../../../../dominio/incidencia.dart';

/// Contrato del datasource remoto para incidencias.
abstract class IncidenciasRemoteDataSource {
  /// Crea una incidencia en el backend y devuelve el modelo con folio.
  Future<IncidenciaModel> reportarIncidencia({
    required int equipoId,
    required TipoProblema tipo,
    required String descripcion,
  });
}

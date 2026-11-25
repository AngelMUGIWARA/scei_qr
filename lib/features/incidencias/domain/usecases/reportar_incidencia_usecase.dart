import '../../../../dominio/incidencia.dart';
import '../../../../dominio/nueva_incidencia.dart';
import '../repositories/incidencias_repository.dart';

/// HU-AL-06: envía el reporte de incidencia al backend.
///
/// El caso de uso delega directamente al repositorio; la validación de
/// campos obligatorios ocurre en la capa de presentación antes de llamarlo.
class ReportarIncidenciaUseCase {
  const ReportarIncidenciaUseCase(this._repository);

  final IncidenciasRepository _repository;

  Future<Incidencia> call(NuevaIncidencia datos) =>
      _repository.reportarIncidencia(datos);
}

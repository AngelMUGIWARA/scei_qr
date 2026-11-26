import '../../../../dominio/uso.dart';
import '../repositories/usos_repository.dart';

/// HU-AL-04: consulta si el alumno tiene un uso activo (también al reabrir
/// la app), para decidir si se muestra el botón "Finalizar uso".
class ObtenerUsoActivoUseCase {
  const ObtenerUsoActivoUseCase(this._repository);

  final UsosRepository _repository;

  Future<Uso?> call() => _repository.obtenerUsoActivo();
}

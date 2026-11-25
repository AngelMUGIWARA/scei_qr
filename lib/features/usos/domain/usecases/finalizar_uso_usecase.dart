import '../../../../dominio/uso.dart';
import '../repositories/usos_repository.dart';

/// HU-AL-04: finaliza el uso activo. El servidor guarda la fecha y hora de
/// fin; la duración se obtiene de `Uso.duracion` con las fechas devueltas.
class FinalizarUsoUseCase {
  const FinalizarUsoUseCase(this._repository);

  final UsosRepository _repository;

  Future<Uso> call(int usoId) => _repository.finalizarUso(usoId);
}

import '../../../../dominio/uso.dart';
import '../repositories/usos_repository.dart';

class IniciarUsoUseCase {
  const IniciarUsoUseCase(this._repository);

  final UsosRepository _repository;

  Future<Uso> call(String qrToken) => _repository.iniciarUso(qrToken);
}

import '../../../../dominio/equipo.dart';
import '../repositories/equipos_repository.dart';

/// HU-AD-06: regenera el código QR del equipo.
///
/// Devuelve el equipo con el `qrToken` nuevo; el token anterior queda
/// invalidado en el servidor (deja de resolver al escanearlo).
class RegenerarQrUseCase {
  const RegenerarQrUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Equipo> call(int id) => _repository.regenerarQr(id);
}

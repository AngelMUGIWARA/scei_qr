import '../../../../dominio/equipo.dart';
import '../repositories/equipos_repository.dart';

/// HU-AL-02: valida un código QR escaneado contra el backend y devuelve
/// el equipo identificado.
///
/// Lanza [NotFoundException] (404 del servidor) cuando el token no
/// pertenece al sistema o el equipo está dado de baja.
class ValidarQrUseCase {
  const ValidarQrUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Equipo> call(String qrToken) => _repository.resolverQr(qrToken);
}

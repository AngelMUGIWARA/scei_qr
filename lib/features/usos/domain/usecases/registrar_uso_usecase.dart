import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../../../dominio/equipo.dart';
import '../registro_uso_resultado.dart';
import '../repositories/cola_usos_pendientes_repository.dart';
import '../repositories/usos_repository.dart';
import '../uso_pendiente.dart';

/// HU-AL-03: registra el uso intentando el envío inmediato y, si no hay
/// conexión, lo deja en una cola local persistente para reintentarlo.
class RegistrarUsoUseCase {
  RegistrarUsoUseCase(this._repository, this._cola);

  final UsosRepository _repository;
  final ColaUsosPendientesRepository _cola;

  Future<RegistroUsoResultado> call({
    required String qrToken,
    required Equipo equipo,
    DateTime? ahora,
  }) async {
    final idempotencyKey = generarIdempotencyKey();

    try {
      final uso = await _repository.iniciarUso(
        qrToken,
        idempotencyKey: idempotencyKey,
      );
      return RegistroUsoResultado.registrado(uso);
    } on NetworkException {
      await _cola.guardar(
        UsoPendiente.desdeEquipo(
          idempotencyKey: idempotencyKey,
          qrToken: qrToken,
          equipo: equipo,
          creadoEn: ahora ?? DateTime.now(),
        ),
      );
      return const RegistroUsoResultado.pendiente();
    }
  }
}

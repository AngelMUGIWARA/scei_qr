import '../../../../core/errors/app_exception.dart';
import '../repositories/cola_usos_pendientes_repository.dart';
import '../repositories/usos_repository.dart';
import '../resultado_sincronizacion.dart';
import '../uso_pendiente.dart';

/// Reenvía los registros de uso que quedaron pendientes por falta de conexión.
class SincronizarUsosPendientesUseCase {
  SincronizarUsosPendientesUseCase(this._repository, this._cola);

  final UsosRepository _repository;
  final ColaUsosPendientesRepository _cola;

  Future<ResultadoSincronizacion> call() async {
    final pendientes = await _cola.listar();
    var sincronizados = 0;
    var fallidos = 0;
    var interrumpido = false;

    for (final pendiente in pendientes) {
      try {
        await _repository.iniciarUso(
          pendiente.qrToken,
          idempotencyKey: pendiente.idempotencyKey,
        );
        await _cola.eliminar(pendiente.idempotencyKey);
        sincronizados++;
      } on NetworkException {
        // Sin conexión: se conserva la cola y se reintenta al reconectar.
        interrumpido = true;
        break;
      } on AuthException {
        // Sin sesión válida no se puede sincronizar; se reintenta más tarde.
        interrumpido = true;
        break;
      } on ConflictException {
        // 409: el uso ya existe en el backend (reintento idempotente) o hay un
        // conflicto no recuperable. Se descarta para no bloquear la cola.
        await _cola.eliminar(pendiente.idempotencyKey);
        sincronizados++;
      } on NotFoundException {
        // Equipo inexistente o dado de baja: no tiene caso reintentarlo.
        await _cola.eliminar(pendiente.idempotencyKey);
      } on ValidationException {
        await _cola.eliminar(pendiente.idempotencyKey);
      } on ForbiddenException {
        await _cola.eliminar(pendiente.idempotencyKey);
      } on ServerException {
        fallidos++;
        await _guardarIntento(pendiente);
      } catch (_) {
        fallidos++;
        await _guardarIntento(pendiente);
      }
    }

    return ResultadoSincronizacion(
      sincronizados: sincronizados,
      fallidos: fallidos,
      pendientesRestantes: await _cola.contar(),
      interrumpido: interrumpido,
    );
  }

  Future<void> _guardarIntento(UsoPendiente pendiente) {
    return _cola.guardar(pendiente.copyWith(intentos: pendiente.intentos + 1));
  }
}

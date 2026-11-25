import '../uso_pendiente.dart';

/// Cola local persistente de registros de uso pendientes de sincronizar.
abstract class ColaUsosPendientesRepository {
  Future<List<UsoPendiente>> listar();

  /// Inserta o actualiza un pendiente según su [UsoPendiente.idempotencyKey].
  Future<void> guardar(UsoPendiente pendiente);

  Future<void> eliminar(String idempotencyKey);

  Future<int> contar();
}

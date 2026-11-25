import '../../domain/repositories/cola_usos_pendientes_repository.dart';
import '../../domain/uso_pendiente.dart';
import '../datasources/local/cola_usos_local_data_source.dart';
import '../models/uso_pendiente_model.dart';

class ColaUsosPendientesRepositoryImpl
    implements ColaUsosPendientesRepository {
  const ColaUsosPendientesRepositoryImpl(this._local);

  final ColaUsosLocalDataSource _local;

  @override
  Future<List<UsoPendiente>> listar() async {
    final modelos = await _local.leer();
    return modelos
        .map((modelo) => modelo.toEntity())
        .toList(growable: false);
  }

  @override
  Future<void> guardar(UsoPendiente pendiente) async {
    final modelos = await _local.leer();
    final modelo = UsoPendienteModel.fromEntity(pendiente);
    final indice = modelos.indexWhere(
      (item) => item.idempotencyKey == pendiente.idempotencyKey,
    );

    final actualizados = List<UsoPendienteModel>.from(modelos);
    if (indice == -1) {
      actualizados.add(modelo);
    } else {
      actualizados[indice] = modelo;
    }

    await _local.guardar(actualizados);
  }

  @override
  Future<void> eliminar(String idempotencyKey) async {
    final modelos = await _local.leer();
    final restantes = modelos
        .where((modelo) => modelo.idempotencyKey != idempotencyKey)
        .toList(growable: false);
    await _local.guardar(restantes);
  }

  @override
  Future<int> contar() async => (await _local.leer()).length;
}

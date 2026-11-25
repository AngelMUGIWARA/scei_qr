import 'package:scei_qr/features/usos/domain/repositories/cola_usos_pendientes_repository.dart';
import 'package:scei_qr/features/usos/domain/uso_pendiente.dart';

/// Cola en memoria para pruebas de unidad y de widgets.
class FakeColaUsosPendientes implements ColaUsosPendientesRepository {
  FakeColaUsosPendientes([List<UsoPendiente>? iniciales])
    : _items = [...?iniciales];

  final List<UsoPendiente> _items;

  List<UsoPendiente> get items => List.unmodifiable(_items);

  @override
  Future<int> contar() async => _items.length;

  @override
  Future<void> eliminar(String idempotencyKey) async {
    _items.removeWhere((item) => item.idempotencyKey == idempotencyKey);
  }

  @override
  Future<void> guardar(UsoPendiente pendiente) async {
    final indice = _items.indexWhere(
      (item) => item.idempotencyKey == pendiente.idempotencyKey,
    );
    if (indice == -1) {
      _items.add(pendiente);
    } else {
      _items[indice] = pendiente;
    }
  }

  @override
  Future<List<UsoPendiente>> listar() async => List.unmodifiable(_items);
}

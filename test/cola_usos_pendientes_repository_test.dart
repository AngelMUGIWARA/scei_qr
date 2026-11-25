import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/features/usos/data/datasources/local/cola_usos_local_data_source.dart';
import 'package:scei_qr/features/usos/data/repositories/cola_usos_pendientes_repository_impl.dart';
import 'package:scei_qr/features/usos/domain/uso_pendiente.dart';
import 'package:shared_preferences/shared_preferences.dart';

UsoPendiente _pendiente(String clave, {int intentos = 0}) {
  return UsoPendiente(
    idempotencyKey: clave,
    qrToken: 'qr-$clave',
    equipoId: 12,
    equipoIdentificador: 'LAB-PC-001',
    creadoEn: DateTime.utc(2026, 11, 24, 10, 30),
    intentos: intentos,
  );
}

ColaUsosPendientesRepositoryImpl _repo() {
  return ColaUsosPendientesRepositoryImpl(
    SharedPreferencesColaUsosLocalDataSource(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ColaUsosPendientesRepositoryImpl — HU-AL-03', () {
    test('guarda, lista y cuenta los pendientes de forma persistente', () async {
      final repo = _repo();
      await repo.guardar(_pendiente('a'));
      await repo.guardar(_pendiente('b'));

      final recuperados = await _repo().listar();

      expect(recuperados, hasLength(2));
      expect(recuperados.map((p) => p.idempotencyKey), ['a', 'b']);
      expect(await _repo().contar(), 2);
    });

    test('guardar con la misma clave actualiza sin duplicar', () async {
      final repo = _repo();
      await repo.guardar(_pendiente('a'));
      await repo.guardar(_pendiente('a', intentos: 3));

      final pendientes = await repo.listar();

      expect(pendientes, hasLength(1));
      expect(pendientes.single.intentos, 3);
    });

    test('eliminar quita solo el pendiente indicado', () async {
      final repo = _repo();
      await repo.guardar(_pendiente('a'));
      await repo.guardar(_pendiente('b'));

      await repo.eliminar('a');

      final pendientes = await repo.listar();
      expect(pendientes, hasLength(1));
      expect(pendientes.single.idempotencyKey, 'b');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';
import 'package:scei_qr/features/usos/domain/usecases/sincronizar_usos_pendientes_usecase.dart';
import 'package:scei_qr/features/usos/domain/uso_pendiente.dart';

import 'fakes_usos.dart';

class _FakeUsosRepository implements UsosRepository {
  _FakeUsosRepository({this.errorPorToken = const {}});

  final Map<String, Object> errorPorToken;
  final List<String> tokens = [];
  final List<String> claves = [];

  @override
  Future<Uso> iniciarUso(String qrToken, {String? idempotencyKey}) async {
    tokens.add(qrToken);
    claves.add(idempotencyKey ?? '');
    final error = errorPorToken[qrToken];
    if (error != null) throw error;
    return Uso(
      id: 1,
      alumnoId: 9,
      equipoId: 12,
      inicio: DateTime.utc(2026, 11, 24, 10, 30),
      estado: EstadoUso.activo,
    );
  }
}

UsoPendiente _pendiente(String clave) {
  return UsoPendiente(
    idempotencyKey: clave,
    qrToken: 'qr-$clave',
    equipoId: 12,
    equipoIdentificador: 'LAB-PC-001',
    creadoEn: DateTime.utc(2026, 11, 24, 10, 30),
  );
}

void main() {
  group('SincronizarUsosPendientesUseCase — HU-AL-03', () {
    test('envía los pendientes con su misma clave y vacía la cola', () async {
      final repo = _FakeUsosRepository();
      final cola = FakeColaUsosPendientes([_pendiente('a'), _pendiente('b')]);

      final resultado = await SincronizarUsosPendientesUseCase(
        repo,
        cola,
      )();

      expect(resultado.sincronizados, 2);
      expect(resultado.fallidos, 0);
      expect(resultado.pendientesRestantes, 0);
      expect(cola.items, isEmpty);
      expect(repo.tokens, ['qr-a', 'qr-b']);
      expect(repo.claves, ['a', 'b']);
    });

    test('sin conexión se detiene y conserva la cola', () async {
      final repo = _FakeUsosRepository(
        errorPorToken: {'qr-a': const NetworkException()},
      );
      final cola = FakeColaUsosPendientes([_pendiente('a'), _pendiente('b')]);

      final resultado = await SincronizarUsosPendientesUseCase(
        repo,
        cola,
      )();

      expect(resultado.interrumpido, isTrue);
      expect(resultado.sincronizados, 0);
      expect(resultado.pendientesRestantes, 2);
      expect(cola.items, hasLength(2));
      expect(repo.tokens, ['qr-a']);
    });

    test('un 409 descarta el pendiente para no bloquear la cola', () async {
      final repo = _FakeUsosRepository(
        errorPorToken: {
          'qr-a': const ConflictException('El equipo ya está en uso.'),
        },
      );
      final cola = FakeColaUsosPendientes([_pendiente('a'), _pendiente('b')]);

      final resultado = await SincronizarUsosPendientesUseCase(
        repo,
        cola,
      )();

      expect(resultado.sincronizados, 2);
      expect(cola.items, isEmpty);
    });

    test('un error de servidor incrementa los intentos y conserva el item', () async {
      final repo = _FakeUsosRepository(
        errorPorToken: {'qr-a': const ServerException()},
      );
      final cola = FakeColaUsosPendientes([_pendiente('a')]);

      final resultado = await SincronizarUsosPendientesUseCase(
        repo,
        cola,
      )();

      expect(resultado.fallidos, 1);
      expect(resultado.pendientesRestantes, 1);
      expect(cola.items.single.intentos, 1);
    });
  });
}

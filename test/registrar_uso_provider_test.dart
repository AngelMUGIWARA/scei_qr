import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';
import 'package:scei_qr/features/usos/domain/usecases/registrar_uso_usecase.dart';
import 'package:scei_qr/features/usos/presentation/providers/registrar_uso_provider.dart';

import 'fakes_usos.dart';

class _FakeUsosRepository implements UsosRepository {
  _FakeUsosRepository({this.uso, this.error});

  Uso? uso;
  Object? error;
  Completer<Uso>? espera;
  final List<String> tokens = [];
  final List<String?> clavesIdempotencia = [];

  @override
  Future<Uso> iniciarUso(String qrToken, {String? idempotencyKey}) async {
    tokens.add(qrToken);
    clavesIdempotencia.add(idempotencyKey);
    final pendiente = espera;
    if (pendiente != null) return pendiente.future;
    if (error != null) throw error!;
    return uso!;
  }
}

const equipo = Equipo(
  id: 12,
  identificador: 'LAB-PC-001',
  nombre: 'LAB-PC-001',
  ubicacion: 'Fila A, Mesa 3',
  activo: true,
  qrToken: 'qr-token',
);

final usoRegistrado = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: DateTime.utc(2026, 11, 8, 15, 30),
  estado: EstadoUso.activo,
  equipo: equipo,
);

RegistrarUsoProvider _provider(
  _FakeUsosRepository repo,
  FakeColaUsosPendientes cola,
) {
  return RegistrarUsoProvider(
    registrarUsoUseCase: RegistrarUsoUseCase(repo, cola),
    equipo: equipo,
    qrToken: 'qr-token',
  );
}

void main() {
  group('RegistrarUsoProvider — HU-AL-03', () {
    test('inicia en estado confirmando (pide confirmación antes de guardar)', () {
      final cola = FakeColaUsosPendientes();
      final provider = _provider(
        _FakeUsosRepository(uso: usoRegistrado),
        cola,
      );
      addTearDown(provider.dispose);

      expect(provider.status, RegistroUsoStatus.confirmando);
      expect(provider.uso, isNull);
      expect(cola.items, isEmpty);
    });

    test('confirmar guarda el uso con el qrToken y una clave de idempotencia', () async {
      final repo = _FakeUsosRepository(uso: usoRegistrado);
      final cola = FakeColaUsosPendientes();
      final provider = _provider(repo, cola);
      addTearDown(provider.dispose);

      await provider.confirmar();

      expect(provider.status, RegistroUsoStatus.registrado);
      expect(provider.uso, same(usoRegistrado));
      expect(repo.tokens, ['qr-token']);
      expect(repo.clavesIdempotencia.single, isNotNull);
      expect(repo.clavesIdempotencia.single, isNotEmpty);
      expect(cola.items, isEmpty);
      expect(provider.error, isNull);
    });

    test('toques repetidos mientras guarda → una sola petición', () async {
      final repo = _FakeUsosRepository();
      final pendiente = Completer<Uso>();
      repo.espera = pendiente;
      final cola = FakeColaUsosPendientes();
      final provider = _provider(repo, cola);
      addTearDown(provider.dispose);

      final primero = provider.confirmar();
      final segundo = provider.confirmar();
      await Future<void>.delayed(Duration.zero);

      expect(provider.status, RegistroUsoStatus.registrando);
      expect(repo.tokens, hasLength(1));

      pendiente.complete(usoRegistrado);
      await Future.wait([primero, segundo]);

      expect(provider.status, RegistroUsoStatus.registrado);
    });

    test('sin conexión deja el uso en la cola y queda pendiente', () async {
      final repo = _FakeUsosRepository(error: const NetworkException());
      final cola = FakeColaUsosPendientes();
      final provider = _provider(repo, cola);
      addTearDown(provider.dispose);

      await provider.confirmar();

      expect(provider.status, RegistroUsoStatus.pendiente);
      expect(provider.error, isNull);
      expect(provider.uso, isNull);
      expect(cola.items, hasLength(1));
      expect(cola.items.single.qrToken, 'qr-token');
      expect(cola.items.single.equipoIdentificador, 'LAB-PC-001');
    });

    test(
      'error 409 muestra el mensaje del backend sin reintento automático',
      () async {
        final repo = _FakeUsosRepository(
          error: const ConflictException(
            'El equipo ya está en uso. Finaliza el uso actual.',
          ),
        );
        final cola = FakeColaUsosPendientes();
        final provider = _provider(repo, cola);
        addTearDown(provider.dispose);

        await provider.confirmar();

        expect(provider.status, RegistroUsoStatus.error);
        expect(
          provider.error,
          'El equipo ya está en uso. Finaliza el uso actual.',
        );
        expect(provider.reintentable, isFalse);
        expect(cola.items, isEmpty);
      },
    );

    test('error de servidor permite reintentar y no encola', () async {
      final repo = _FakeUsosRepository(error: const ServerException());
      final cola = FakeColaUsosPendientes();
      final provider = _provider(repo, cola);
      addTearDown(provider.dispose);

      await provider.confirmar();

      expect(provider.status, RegistroUsoStatus.error);
      expect(provider.reintentable, isTrue);
      expect(cola.items, isEmpty);
    });
  });
}

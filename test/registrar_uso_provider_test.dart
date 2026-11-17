import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';
import 'package:scei_qr/features/usos/domain/usecases/iniciar_uso_usecase.dart';
import 'package:scei_qr/features/usos/presentation/providers/registrar_uso_provider.dart';

class _FakeUsosRepository implements UsosRepository {
  _FakeUsosRepository({this.uso, this.error});

  Uso? uso;
  Object? error;
  Completer<Uso>? espera;
  final List<String> tokens = [];

  @override
  Future<Uso> iniciarUso(String qrToken) async {
    tokens.add(qrToken);
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

RegistrarUsoProvider _provider(_FakeUsosRepository repo) {
  return RegistrarUsoProvider(
    iniciarUsoUseCase: IniciarUsoUseCase(repo),
    equipo: equipo,
    qrToken: 'qr-token',
  );
}

void main() {
  group('RegistrarUsoProvider — HU-AL-03', () {
    test(
      'inicia en estado confirmando (pide confirmación antes de guardar)',
      () {
        final provider = _provider(_FakeUsosRepository(uso: usoRegistrado));
        addTearDown(provider.dispose);

        expect(provider.status, RegistroUsoStatus.confirmando);
        expect(provider.uso, isNull);
      },
    );

    test('confirmar guarda el uso con el qrToken escaneado', () async {
      final repo = _FakeUsosRepository(uso: usoRegistrado);
      final provider = _provider(repo);
      addTearDown(provider.dispose);

      await provider.confirmar();

      expect(provider.status, RegistroUsoStatus.registrado);
      expect(provider.uso, same(usoRegistrado));
      expect(repo.tokens, ['qr-token']);
      expect(provider.error, isNull);
    });

    test('toques repetidos mientras guarda → una sola petición', () async {
      final repo = _FakeUsosRepository();
      final pendiente = Completer<Uso>();
      repo.espera = pendiente;
      final provider = _provider(repo);
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

    test('sin conexión informa y permite reintentar sin reescanear', () async {
      final repo = _FakeUsosRepository(error: const NetworkException());
      final provider = _provider(repo);
      addTearDown(provider.dispose);

      await provider.confirmar();

      expect(provider.status, RegistroUsoStatus.error);
      expect(provider.error, const NetworkException().message);
      expect(provider.reintentable, isTrue);

      await provider.reintentar();

      expect(provider.status, RegistroUsoStatus.error);
      expect(repo.tokens, ['qr-token', 'qr-token']);
    });

    test(
      'error 409 muestra el mensaje del backend sin reintento automático',
      () async {
        final repo = _FakeUsosRepository(
          error: const ConflictException(
            'El equipo ya está en uso. Finaliza el uso actual.',
          ),
        );
        final provider = _provider(repo);
        addTearDown(provider.dispose);

        await provider.confirmar();

        expect(provider.status, RegistroUsoStatus.error);
        expect(
          provider.error,
          'El equipo ya está en uso. Finaliza el uso actual.',
        );
        expect(provider.reintentable, isFalse);
      },
    );

    test('error de servidor permite reintentar', () async {
      final repo = _FakeUsosRepository(error: const ServerException());
      final provider = _provider(repo);
      addTearDown(provider.dispose);

      await provider.confirmar();

      expect(provider.status, RegistroUsoStatus.error);
      expect(provider.reintentable, isTrue);
    });
  });
}

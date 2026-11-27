import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';
import 'package:scei_qr/features/usos/domain/usecases/finalizar_uso_usecase.dart';
import 'package:scei_qr/features/usos/domain/usecases/obtener_uso_activo_usecase.dart';
import 'package:scei_qr/features/usos/presentation/providers/uso_activo_provider.dart';

class _FakeUsosRepository implements UsosRepository {
  Uso? activo;
  Object? errorConsulta;
  Uso? finalizado;
  Object? errorFinalizar;
  Completer<Uso>? espera;
  final List<int> finalizados = [];

  @override
  Future<Uso> iniciarUso(String qrToken) async => throw UnimplementedError();

  @override
  Future<Uso?> obtenerUsoActivo() async {
    if (errorConsulta != null) throw errorConsulta!;
    return activo;
  }

  @override
  Future<Uso> finalizarUso(int usoId) async {
    finalizados.add(usoId);
    final pendiente = espera;
    if (pendiente != null) return pendiente.future;
    if (errorFinalizar != null) throw errorFinalizar!;
    return finalizado!;
  }
}

const _equipo = Equipo(
  id: 12,
  identificador: 'LAB-PC-001',
  ubicacion: 'Fila A, Mesa 3',
  activo: true,
);

final _activo = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: DateTime.utc(2026, 11, 8, 15, 30),
  estado: EstadoUso.activo,
  equipo: _equipo,
);

final _finalizado = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: DateTime.utc(2026, 11, 8, 15, 30),
  fin: DateTime.utc(2026, 11, 8, 17, 5),
  estado: EstadoUso.finalizado,
  equipo: _equipo,
);

UsoActivoProvider _provider(_FakeUsosRepository repo) => UsoActivoProvider(
  obtenerUsoActivoUseCase: ObtenerUsoActivoUseCase(repo),
  finalizarUsoUseCase: FinalizarUsoUseCase(repo),
);

void main() {
  group('UsoActivoProvider.cargar — HU-AL-04', () {
    test('con uso activo muestra el botón "Finalizar uso"', () async {
      final provider = _provider(_FakeUsosRepository()..activo = _activo);

      await provider.cargar();

      expect(provider.status, UsoActivoStatus.activo);
      expect(provider.usoActivo, same(_activo));
      expect(provider.muestraBotonFinalizar, isTrue);
    });

    test('sin uso activo no muestra el botón', () async {
      final provider = _provider(_FakeUsosRepository());

      await provider.cargar();

      expect(provider.status, UsoActivoStatus.sinUso);
      expect(provider.muestraBotonFinalizar, isFalse);
    });

    test('error de consulta: mensaje y sin botón', () async {
      final provider = _provider(
        _FakeUsosRepository()..errorConsulta = const NetworkException(),
      );

      await provider.cargar();

      expect(provider.status, UsoActivoStatus.error);
      expect(provider.mensaje, const NetworkException().message);
      expect(provider.muestraBotonFinalizar, isFalse);
    });
  });

  group('UsoActivoProvider.finalizar — HU-AL-04', () {
    test('finaliza el uso activo y deja el resumen', () async {
      final repo = _FakeUsosRepository()
        ..activo = _activo
        ..finalizado = _finalizado;
      final provider = _provider(repo);
      await provider.cargar();

      await provider.finalizar();

      expect(repo.finalizados, [5]);
      expect(provider.status, UsoActivoStatus.finalizado);
      expect(provider.usoFinalizado, same(_finalizado));
      expect(
        provider.usoFinalizado!.duracion,
        const Duration(hours: 1, minutes: 35),
      );
      expect(provider.usoActivo, isNull);
      expect(provider.muestraBotonFinalizar, isFalse);
    });

    test('mientras finaliza ignora un segundo toque', () async {
      final repo = _FakeUsosRepository()
        ..activo = _activo
        ..espera = Completer<Uso>();
      final provider = _provider(repo);
      await provider.cargar();

      final primero = provider.finalizar();
      expect(provider.status, UsoActivoStatus.finalizando);
      await provider.finalizar();
      repo.espera!.complete(_finalizado);
      await primero;

      expect(repo.finalizados, [5]);
      expect(provider.status, UsoActivoStatus.finalizado);
    });

    test(
      'sin conexión conserva el uso activo y el botón, con mensaje',
      () async {
        final repo = _FakeUsosRepository()
          ..activo = _activo
          ..errorFinalizar = const NetworkException();
        final provider = _provider(repo);
        await provider.cargar();

        await provider.finalizar();

        expect(provider.status, UsoActivoStatus.activo);
        expect(provider.usoActivo, same(_activo));
        expect(provider.muestraBotonFinalizar, isTrue);
        expect(provider.mensaje, const NetworkException().message);

        // Puede reintentarse sin volver a consultar.
        repo
          ..errorFinalizar = null
          ..finalizado = _finalizado;
        await provider.finalizar();
        expect(provider.status, UsoActivoStatus.finalizado);
        expect(repo.finalizados, [5, 5]);
      },
    );

    test('409 "El uso ya fue finalizado": oculta el botón y avisa', () async {
      final provider = _provider(
        _FakeUsosRepository()
          ..activo = _activo
          ..errorFinalizar = const ConflictException(
            'El uso ya fue finalizado',
          ),
      );
      await provider.cargar();

      await provider.finalizar();

      expect(provider.status, UsoActivoStatus.sinUso);
      expect(provider.muestraBotonFinalizar, isFalse);
      expect(provider.mensaje, 'El uso ya fue finalizado');
    });

    test('403 (uso de otro alumno): oculta el botón y avisa', () async {
      final provider = _provider(
        _FakeUsosRepository()
          ..activo = _activo
          ..errorFinalizar = const ForbiddenException(
            'Solo puedes finalizar tus propios usos.',
          ),
      );
      await provider.cargar();

      await provider.finalizar();

      expect(provider.status, UsoActivoStatus.sinUso);
      expect(provider.mensaje, 'Solo puedes finalizar tus propios usos.');
    });

    test('404: oculta el botón y avisa', () async {
      final provider = _provider(
        _FakeUsosRepository()
          ..activo = _activo
          ..errorFinalizar = const NotFoundException(
            'El registro de uso no existe.',
          ),
      );
      await provider.cargar();

      await provider.finalizar();

      expect(provider.status, UsoActivoStatus.sinUso);
      expect(provider.mensaje, 'El registro de uso no existe.');
    });
  });
}

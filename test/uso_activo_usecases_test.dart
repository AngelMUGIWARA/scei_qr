import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';
import 'package:scei_qr/features/usos/domain/usecases/finalizar_uso_usecase.dart';
import 'package:scei_qr/features/usos/domain/usecases/obtener_uso_activo_usecase.dart';

class _FakeUsosRepository implements UsosRepository {
  Uso? activo;
  Uso? finalizado;
  Object? error;
  final List<int> finalizados = [];

  @override
  Future<Uso> iniciarUso(String qrToken) async => throw UnimplementedError();

  @override
  Future<Uso?> obtenerUsoActivo() async {
    if (error != null) throw error!;
    return activo;
  }

  @override
  Future<Uso> finalizarUso(int usoId) async {
    finalizados.add(usoId);
    if (error != null) throw error!;
    return finalizado!;
  }
}

final _activo = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: DateTime.utc(2026, 11, 8, 15, 30),
  estado: EstadoUso.activo,
);

final _finalizado = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: DateTime.utc(2026, 11, 8, 15, 30),
  fin: DateTime.utc(2026, 11, 8, 16, 15),
  estado: EstadoUso.finalizado,
);

void main() {
  group('ObtenerUsoActivoUseCase — HU-AL-04', () {
    test('devuelve el uso activo del repositorio', () async {
      final repo = _FakeUsosRepository()..activo = _activo;

      final uso = await ObtenerUsoActivoUseCase(repo)();

      expect(uso, same(_activo));
    });

    test('devuelve null cuando no hay uso activo', () async {
      final repo = _FakeUsosRepository();

      expect(await ObtenerUsoActivoUseCase(repo)(), isNull);
    });

    test('propaga los errores del repositorio', () async {
      final repo = _FakeUsosRepository()..error = const NetworkException();

      await expectLater(
        ObtenerUsoActivoUseCase(repo)(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('FinalizarUsoUseCase — HU-AL-04', () {
    test(
      'finaliza el uso indicado y la duración sale de fin - inicio',
      () async {
        final repo = _FakeUsosRepository()..finalizado = _finalizado;

        final uso = await FinalizarUsoUseCase(repo)(5);

        expect(repo.finalizados, [5]);
        expect(uso.estaActivo, isFalse);
        expect(uso.fin, DateTime.utc(2026, 11, 8, 16, 15));
        expect(uso.duracion, const Duration(minutes: 45));
      },
    );

    test('propaga el 409 "El uso ya fue finalizado"', () async {
      final repo = _FakeUsosRepository()
        ..error = const ConflictException('El uso ya fue finalizado');

      await expectLater(
        FinalizarUsoUseCase(repo)(5),
        throwsA(isA<ConflictException>()),
      );
    });
  });
}

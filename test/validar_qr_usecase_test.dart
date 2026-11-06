import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/validar_qr_usecase.dart';

class FakeEquiposRepository implements EquiposRepository {
  FakeEquiposRepository({this.alResolver});

  Future<Equipo> Function(String)? alResolver;
  int llamadas = 0;
  String? ultimoToken;

  @override
  Future<Equipo> resolverQr(String qrToken) async {
    llamadas++;
    ultimoToken = qrToken;
    final handler = alResolver;
    if (handler == null) {
      return const Equipo(
        id: 12,
        identificador: 'LAB-PC-001',
        ubicacion: 'Fila A, Mesa 3',
        activo: true,
        qrToken: 'qr-token',
      );
    }
    return handler(qrToken);
  }

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async =>
      throw UnimplementedError();

  @override
  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  }) async => throw UnimplementedError();

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async => throw UnimplementedError();

  @override
  Future<Equipo> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async => throw UnimplementedError();

  @override
  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo}) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> regenerarQr(int id) async => throw UnimplementedError();

  @override
  Future<Uint8List> obtenerImagenQr(int id) async =>
      throw UnimplementedError();
}

void main() {
  group('ValidarQrUseCase', () {
    test('delega en el repositorio y devuelve el equipo cuando el token es válido', () async {
      final repo = FakeEquiposRepository();
      final useCase = ValidarQrUseCase(repo);

      final equipo = await useCase('qr-token');

      expect(equipo.identificador, 'LAB-PC-001');
      expect(repo.llamadas, 1);
      expect(repo.ultimoToken, 'qr-token');
    });

    test('propaga NotFoundException cuando el repositorio lanza 404', () async {
      final repo = FakeEquiposRepository(
        alResolver: (_) async => throw const NotFoundException('QR no encontrado'),
      );
      final useCase = ValidarQrUseCase(repo);

      await expectLater(
        useCase('token-invalido'),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'QR no encontrado',
          ),
        ),
      );
      expect(repo.llamadas, 1);
      expect(repo.ultimoToken, 'token-invalido');
    });

    test('propaga AuthException cuando el repositorio lanza 401', () async {
      final repo = FakeEquiposRepository(
        alResolver: (_) async => throw const AuthException(),
      );
      final useCase = ValidarQrUseCase(repo);

      await expectLater(
        useCase('qr-token'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}

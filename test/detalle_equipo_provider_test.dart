import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/obtener_equipo_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/obtener_imagen_qr_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/regenerar_qr_usecase.dart';
import 'package:scei_qr/features/equipos/presentation/providers/detalle_equipo_provider.dart';

class FakeEquiposRepository implements EquiposRepository {
  FakeEquiposRepository({this.equipo, this.errorQr, this.errorRegenerar});

  Equipo? equipo;
  Object? errorQr;
  Object? errorRegenerar;
  int imagenesQr = 0;
  int regeneraciones = 0;
  String? ultimoTokenGenerado;

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async {
    if (equipo == null) throw const NetworkException();
    return equipo!;
  }

  @override
  Future<Uint8List> obtenerImagenQr(int id) async {
    imagenesQr++;
    if (errorQr != null) throw errorQr!;
    return Uint8List.fromList([137, 80, 78, 71]);
  }

  @override
  Future<Equipo> resolverQr(String qrToken) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> regenerarQr(int id) async {
    regeneraciones++;
    if (errorRegenerar != null) throw errorRegenerar!;
    final actual = equipo!;
    ultimoTokenGenerado = 'qr-token-${regeneraciones + 1}';
    equipo = actual.copyWith(qrToken: ultimoTokenGenerado);
    return equipo!;
  }

  @override
  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  }) async => throw UnimplementedError();

  @override
  Future<Equipo> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async => throw UnimplementedError();

  @override
  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo}) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async =>
      throw UnimplementedError();
}

const equipo = Equipo(
  id: 12,
  identificador: 'PC-001',
  nombre: 'Equipo de laboratorio',
  descripcion: 'Dell OptiPlex',
  ubicacion: 'Fila A',
  activo: true,
  qrToken: 'qr-token-1',
);

DetalleEquipoProvider construirProvider(FakeEquiposRepository repo) {
  return DetalleEquipoProvider(
    equipoId: equipo.id,
    obtenerEquipoUseCase: ObtenerEquipoUseCase(repo),
    obtenerImagenQrUseCase: ObtenerImagenQrUseCase(repo),
    regenerarQrUseCase: RegenerarQrUseCase(repo),
  );
}

void main() {
  group('DetalleEquipoProvider — HU-AD-06', () {
    test('carga el equipo y su imagen QR', () async {
      final repo = FakeEquiposRepository(equipo: equipo);
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);

      await provider.cargar();

      expect(provider.listo, isTrue);
      expect(provider.equipo!.identificador, 'PC-001');
      expect(provider.qrBytes, isNotNull);
      expect(provider.errorEquipo, isNull);
      expect(provider.errorQr, isNull);
      expect(repo.imagenesQr, 1);
    });

    test('un fallo al cargar el QR no bloquea el detalle del equipo', () async {
      final repo = FakeEquiposRepository(
        equipo: equipo,
        errorQr: const NetworkException(),
      );
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);

      await provider.cargar();

      expect(provider.listo, isTrue);
      expect(provider.qrBytes, isNull);
      expect(
        provider.errorQr,
        'No se pudo conectar con el servidor. Revisa tu conexión e '
        'inténtalo de nuevo.',
      );
    });

    test('reintentar el QR vuelve a descargarlo', () async {
      final repo = FakeEquiposRepository(
        equipo: equipo,
        errorQr: const NetworkException(),
      );
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);
      await provider.cargar();
      repo.errorQr = null;

      await provider.cargarQr();

      expect(provider.errorQr, isNull);
      expect(provider.qrBytes, isNotNull);
      expect(repo.imagenesQr, 2);
    });

    test('regenerar cambia el token y marca el QR anterior como invalidado', () async {
      final repo = FakeEquiposRepository(equipo: equipo);
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);
      await provider.cargar();

      final ok = await provider.regenerarQr();

      expect(ok, isTrue);
      expect(repo.regeneraciones, 1);
      expect(provider.equipo!.qrToken, 'qr-token-2');
      // CA: se informa que el anterior dejó de ser válido.
      expect(provider.qrInvalidado, isTrue);
      // El PNG mostrado corresponde al QR nuevo (se recargó).
      expect(repo.imagenesQr, 2);
      expect(provider.regenerando, isFalse);
    });

    test('limpiarMensajes resetea el aviso de invalidación', () async {
      final repo = FakeEquiposRepository(equipo: equipo);
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);
      await provider.cargar();
      await provider.regenerarQr();

      provider.limpiarMensajes();

      expect(provider.qrInvalidado, isFalse);
      expect(provider.errorAccion, isNull);
    });

    test('regenerar fallido expone el error y no marca invalidación', () async {
      final repo = FakeEquiposRepository(
        equipo: equipo,
        errorRegenerar: const ForbiddenException(),
      );
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);
      await provider.cargar();

      final ok = await provider.regenerarQr();

      expect(ok, isFalse);
      expect(repo.regeneraciones, 1);
      expect(provider.errorAccion, 'No tienes permisos para realizar esta acción.');
      expect(provider.qrInvalidado, isFalse);
      expect(provider.equipo!.qrToken, 'qr-token-1');
      expect(provider.regenerando, isFalse);
    });

    test('carga con error expone errorEquipo para reintentar', () async {
      final repo = FakeEquiposRepository(); // sin equipo → NetworkException
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);

      await provider.cargar();

      expect(provider.listo, isFalse);
      expect(provider.errorEquipo, isNotNull);
      expect(provider.cargandoEquipo, isFalse);
    });
  });
}

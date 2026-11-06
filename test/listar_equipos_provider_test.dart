import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/cambiar_estado_equipo_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/listar_equipos_usecase.dart';
import 'package:scei_qr/features/equipos/presentation/providers/listar_equipos_provider.dart';

class FakeEquiposRepository implements EquiposRepository {
  List<Equipo> equipos = [];
  Object? error;
  String? ultimaQ;
  String? ultimaUbicacion;
  bool? ultimoActivo;
  bool? ultimoEstadoSolicitado;
  int listados = 0;

  @override
  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  }) async {
    listados++;
    ultimaQ = q;
    ultimaUbicacion = ubicacion;
    ultimoActivo = activo;
    if (error != null) throw error!;
    return equipos;
  }

  @override
  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo}) async {
    ultimoEstadoSolicitado = activo;
    if (error != null) throw error!;
    final actual = equipos.firstWhere((equipo) => equipo.id == id);
    final actualizado = actual.copyWith(activo: activo);
    equipos = [
      for (final equipo in equipos)
        if (equipo.id == id) actualizado else equipo,
    ];
    return actualizado;
  }

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async => throw UnimplementedError();

  @override
  Future<Equipo> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async => throw UnimplementedError();

  @override
  Future<Equipo> regenerarQr(int id) async => throw UnimplementedError();

  @override
  Future<Uint8List> obtenerImagenQr(int id) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> resolverQr(String qrToken) async =>
      throw UnimplementedError();
}

const equipoActivo = Equipo(
  id: 1,
  identificador: 'PC-001',
  nombre: 'Equipo de laboratorio',
  ubicacion: 'Fila A',
  activo: true,
);

ListarEquiposProvider construirProvider(
  FakeEquiposRepository repo, {
  Duration debounce = const Duration(hours: 1),
}) {
  return ListarEquiposProvider(
    listarEquiposUseCase: ListarEquiposUseCase(repo),
    cambiarEstadoEquipoUseCase: CambiarEstadoEquipoUseCase(repo),
    debounce: debounce,
  );
}

void main() {
  group('ListarEquiposProvider', () {
    test('carga los equipos y pasa los filtros al caso de uso', () async {
      final repo = FakeEquiposRepository()..equipos = [equipoActivo];
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);

      await provider.cargar();

      expect(provider.status, ListarEquiposStatus.cargado);
      expect(provider.equipos, [equipoActivo]);
      expect(provider.errorMessage, isNull);

      provider.actualizarBusqueda(' PC ');
      provider.actualizarUbicacion(' Fila A ');
      await provider.cargar();

      expect(repo.ultimaQ, ' PC ');
      expect(repo.ultimaUbicacion, ' Fila A ');
      expect(provider.hayFiltros, isTrue);
    });

    test('filtra por estado activo y limpia los filtros', () async {
      final repo = FakeEquiposRepository()..equipos = [equipoActivo];
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);

      provider.actualizarEstado(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repo.ultimoActivo, isFalse);
      expect(provider.activo, isFalse);

      provider.limpiarFiltros();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.activo, isNull);
      expect(provider.busqueda, isEmpty);
      expect(provider.ubicacion, isEmpty);
      expect(repo.ultimoActivo, isNull);
    });

    test('expone el error cuando falla la carga', () async {
      final repo = FakeEquiposRepository()..error = const NetworkException();
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);

      await provider.cargar();

      expect(provider.status, ListarEquiposStatus.error);
      expect(
        provider.errorMessage,
        'No se pudo conectar con el servidor. Revisa tu conexión e '
        'inténtalo de nuevo.',
      );
      expect(provider.equipos, isEmpty);
    });

    test('dar de baja actualiza el estado y recarga el listado', () async {
      final repo = FakeEquiposRepository()..equipos = [equipoActivo];
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);
      await provider.cargar();

      final ok = await provider.cambiarEstado(equipoActivo);

      expect(ok, isTrue);
      expect(repo.ultimoEstadoSolicitado, isFalse);
      expect(provider.equipos.single.activo, isFalse);
      expect(provider.mensajeAccion, contains('dado de baja'));
      expect(provider.procesandoId, isNull);
    });

    test('reactivar envía activo=true', () async {
      final inactivo = equipoActivo.copyWith(activo: false);
      final repo = FakeEquiposRepository()..equipos = [inactivo];
      final provider = construirProvider(repo);
      addTearDown(provider.dispose);
      await provider.cargar();

      await provider.cambiarEstado(inactivo);

      expect(repo.ultimoEstadoSolicitado, isTrue);
      expect(provider.equipos.single.activo, isTrue);
      expect(provider.mensajeAccion, contains('reactivado'));
    });

    test(
      'si falla el cambio de estado conserva el error y el listado',
      () async {
        final repo = FakeEquiposRepository()..equipos = [equipoActivo];
        final provider = construirProvider(repo);
        addTearDown(provider.dispose);
        await provider.cargar();
        repo.error = const ForbiddenException();

        final ok = await provider.cambiarEstado(equipoActivo);

        expect(ok, isFalse);
        expect(provider.errorAccion, isNotNull);
        expect(provider.equipos.single.activo, isTrue);
        expect(provider.procesandoId, isNull);
      },
    );
  });
}

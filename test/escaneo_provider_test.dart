import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/validar_qr_usecase.dart';
import 'package:scei_qr/features/escaneo/domain/permiso_camara.dart';
import 'package:scei_qr/features/escaneo/presentation/providers/escaneo_provider.dart';

/// Repo falso: solo `resolverQr` está operativo; registra cada llamada.
class _FakeEquiposRepository implements EquiposRepository {
  _FakeEquiposRepository({this.equipo, this.error});

  Equipo? equipo;
  Object? error;
  final List<String> tokens = [];

  @override
  Future<Equipo> resolverQr(String qrToken) async {
    tokens.add(qrToken);
    if (error != null) throw error!;
    return equipo!;
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
  Future<Uint8List> obtenerImagenQr(int id) async => throw UnimplementedError();
}

/// Permiso falso configurable sin tocar el plugin `permission_handler`.
class _FakePermisoCamara implements PermisoCamara {
  _FakePermisoCamara({
    this.concedido = false,
    this.puedeSolicitar = false,
    this.habilitaTrasAjustes = false,
  });

  bool concedido;
  final bool puedeSolicitar;
  final bool habilitaTrasAjustes;
  int solicitudes = 0;
  int aperturasAjustes = 0;

  @override
  Future<bool> estaConcedido() async => concedido;

  @override
  Future<bool> solicitar() async {
    solicitudes++;
    if (puedeSolicitar) concedido = true;
    return concedido;
  }

  @override
  Future<bool> abrirAjustes() async {
    aperturasAjustes++;
    if (habilitaTrasAjustes) concedido = true;
    return true;
  }
}

const equipo = Equipo(
  id: 7,
  identificador: 'LT-101',
  nombre: 'Laboratorio 1',
  descripcion: 'Lenovo ThinkCentre',
  ubicacion: 'Lab de redes',
  activo: true,
  qrToken: 'token-valido',
);

EscaneoProvider _construirProvider({
  required _FakeEquiposRepository repo,
  required _FakePermisoCamara permiso,
}) {
  return EscaneoProvider(
    validarQrUseCase: ValidarQrUseCase(repo),
    permisoCamara: permiso,
  );
}

void main() {
  group('EscaneoProvider — HU-AL-02 (permisos)', () {
    test('permiso concedido → escaneando sin solicitar', () async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(concedido: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);

      await provider.iniciar();

      expect(provider.status, EscaneoStatus.escaneando);
      expect(permiso.solicitudes, 0);
    });

    test('permiso no concedido → se solicita y se otorga → escaneando',
        () async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(puedeSolicitar: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);

      await provider.iniciar();

      expect(provider.status, EscaneoStatus.escaneando);
      expect(permiso.solicitudes, 1);
    });

    test('permiso denegado → permisoDenegado con explicación de ajustes',
        () async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara();
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);

      await provider.iniciar();

      expect(provider.status, EscaneoStatus.permisoDenegado);
      expect(permiso.solicitudes, 1);
    });

    test('abrirAjustes habilita el permiso y revalida → escaneando', () async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(habilitaTrasAjustes: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);

      await provider.iniciar();
      expect(provider.status, EscaneoStatus.permisoDenegado);

      await provider.abrirAjustes();

      expect(permiso.aperturasAjustes, 1);
      expect(provider.status, EscaneoStatus.escaneando);
    });
  });

  group('EscaneoProvider — HU-AL-02 (validación del QR)', () {
    test('QR válido → equipoEncontrado con el equipo resuelto', () async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(concedido: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);
      await provider.iniciar();

      await provider.procesarQr('token-valido');

      expect(provider.status, EscaneoStatus.equipoEncontrado);
      expect(provider.equipo, isNotNull);
      expect(provider.equipo!.identificador, 'LT-101');
      expect(repo.tokens, ['token-valido']);
      expect(provider.errorQr, isNull);
    });

    test('QR inexistente (404) → errorQr con mensaje y opción de reintentar',
        () async {
      final repo = _FakeEquiposRepository(
        error: const NotFoundException('QR no válido o equipo inactivo'),
      );
      final permiso = _FakePermisoCamara(concedido: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);
      await provider.iniciar();

      await provider.procesarQr('qr-desconocido');

      expect(provider.status, EscaneoStatus.errorQr);
      expect(provider.errorQr, 'QR no válido o equipo inactivo');
      expect(provider.equipo, isNull);

      // CA: permite reintentar → vuelve a la cámara y limpia el error.
      provider.reintentar();
      expect(provider.status, EscaneoStatus.escaneando);
      expect(provider.errorQr, isNull);
    });

    test('QR de equipo dado de baja (404 del backend) → errorQr', () async {
      final repo = _FakeEquiposRepository(
        error: const NotFoundException('QR no válido o equipo inactivo'),
      );
      final permiso = _FakePermisoCamara(concedido: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);
      await provider.iniciar();

      await provider.procesarQr('qr-equipo-baja');

      expect(provider.status, EscaneoStatus.errorQr);
      expect(provider.errorQr, contains('inactivo'));
      // No se continúa: el equipo nunca se resuelve.
      expect(provider.equipo, isNull);
    });

    test('lecturas duplicadas (frames seguidos) → una sola validación',
        () async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(concedido: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);
      await provider.iniciar();

      // Dos frames con el mismo token casi al mismo tiempo.
      final primero = provider.procesarQr('token-valido');
      final segundo = provider.procesarQr('token-valido');
      await Future.wait([primero, segundo]);

      expect(repo.tokens, hasLength(1));
      expect(provider.status, EscaneoStatus.equipoEncontrado);
    });

    test('QR vacío o en blanco → se ignora y sigue escaneando', () async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(concedido: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);
      await provider.iniciar();

      await provider.procesarQr('   ');

      expect(repo.tokens, isEmpty);
      expect(provider.status, EscaneoStatus.escaneando);
    });

    test('error de red → errorQr con mensaje genérico y reintentable',
        () async {
      final repo = _FakeEquiposRepository(error: const NetworkException());
      final permiso = _FakePermisoCamara(concedido: true);
      final provider = _construirProvider(repo: repo, permiso: permiso);
      addTearDown(provider.dispose);
      await provider.iniciar();

      await provider.procesarQr('token-valido');

      expect(provider.status, EscaneoStatus.errorQr);
      expect(provider.errorQr, isNotNull);

      provider.reintentar();
      expect(provider.status, EscaneoStatus.escaneando);
    });
  });
}

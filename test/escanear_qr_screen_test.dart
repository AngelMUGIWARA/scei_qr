import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/validar_qr_usecase.dart';
import 'package:scei_qr/features/escaneo/domain/permiso_camara.dart';
import 'package:scei_qr/features/escaneo/presentation/screens/escanear_qr_screen.dart';

class _FakeEquiposRepository implements EquiposRepository {
  _FakeEquiposRepository({this.equipo, this.error});

  Equipo? equipo;
  Object? error;
  final List<String> tokens = [];

  /// Si existe, `resolverQr` se queda esperando a que el test lo complete
  /// (para observar el estado intermedio "validando").
  Completer<Equipo>? espera;

  @override
  Future<Equipo> resolverQr(String qrToken) async {
    tokens.add(qrToken);
    final pendiente = espera;
    if (pendiente != null) return pendiente.future;
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

class _FakePermisoCamara implements PermisoCamara {
  _FakePermisoCamara({
    this.concedido = false,
    this.concedeEnReintento = false,
  });

  bool concedido;

  /// Primer "solicitar" denegado; concede a partir del segundo
  /// (simula que el usuario acaba de habilitarlo y pulsa "Reintentar").
  final bool concedeEnReintento;
  int solicitudes = 0;
  int aperturasAjustes = 0;

  @override
  Future<bool> estaConcedido() async => concedido;

  @override
  Future<bool> solicitar() async {
    solicitudes++;
    if (concedeEnReintento && solicitudes > 1) {
      concedido = true;
    }
    return concedido;
  }

  @override
  Future<bool> abrirAjustes() async {
    aperturasAjustes++;
    return true;
  }
}

/// Cámara falsa: registra el callback de detección para que el test pueda
/// "escanear" un QR sin cámara real.
class _CamaraFake {
  void Function(String valor)? onDetectado;

  Widget construir(BuildContext context, void Function(String) detectado) {
    onDetectado = detectado;
    return const SizedBox(key: Key('camara_fake'));
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

Future<void> _pantalla(
  WidgetTester tester, {
  required _FakeEquiposRepository repo,
  required _FakePermisoCamara permiso,
  required _CamaraFake camara,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: EscanearQrScreen(
        validarQrUseCase: ValidarQrUseCase(repo),
        permisoCamara: permiso,
        camaraBuilder: camara.construir,
      ),
    ),
  );
  await tester.pump(); // iniciar() resuelve el permiso
}

void main() {
  group('EscanearQrScreen — HU-AL-02 (cámara y permisos)', () {
    testWidgets('permiso concedido → muestra la cámara y la instrucción',
        (tester) async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(concedido: true);
      final camara = _CamaraFake();

      await _pantalla(tester, repo: repo, permiso: permiso, camara: camara);

      expect(find.byKey(const Key('camara_fake')), findsOneWidget);
      expect(find.byKey(const Key('escaneo_hint')), findsOneWidget);
      expect(
        find.text('Apunta al código QR del equipo'),
        findsOneWidget,
      );
    });

    testWidgets(
        'permiso denegado → explica cómo habilitarlo y ofrece '
        '"Abrir ajustes" + "Reintentar"', (tester) async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(); // niega todo
      final camara = _CamaraFake();

      await _pantalla(tester, repo: repo, permiso: permiso, camara: camara);

      expect(find.byKey(const Key('escaneo_permiso_denegado')), findsOneWidget);
      expect(find.text('Se necesita el permiso de cámara'), findsOneWidget);
      expect(find.byKey(const Key('escaneo_abrir_ajustes')), findsOneWidget);
      expect(find.byKey(const Key('escaneo_reintentar_permiso')), findsOneWidget);
      // CA: con el permiso denegado NO se usa la cámara.
      expect(find.byKey(const Key('camara_fake')), findsNothing);

      // "Abrir ajustes" → llama a openAppSettings y revalida el permiso.
      await tester.tap(find.byKey(const Key('escaneo_abrir_ajustes')));
      await tester.pump();

      expect(permiso.aperturasAjustes, 1);
      // Sigue denegado (el usuario todavía no lo habilitó) → la vista
      // de explicación permanece con la opción de reintentar.
      expect(find.byKey(const Key('escaneo_permiso_denegado')), findsOneWidget);
    });

    testWidgets('"Reintentar" tras habilitar el permiso → vuelve a la cámara',
        (tester) async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      // El primer "solicitar" se niega; el siguiente (tras Reintentar) pasa.
      final permiso = _FakePermisoCamara(concedeEnReintento: true);
      final camara = _CamaraFake();

      await _pantalla(tester, repo: repo, permiso: permiso, camara: camara);
      expect(find.byKey(const Key('escaneo_permiso_denegado')), findsOneWidget);

      await tester.tap(find.byKey(const Key('escaneo_reintentar_permiso')));
      await tester.pump();

      expect(permiso.solicitudes, 2);
      expect(find.byKey(const Key('camara_fake')), findsOneWidget);
      expect(find.byKey(const Key('escaneo_permiso_denegado')), findsNothing);
    });
  });

  group('EscanearQrScreen — HU-AL-02 (flujo de validación)', () {
    testWidgets('QR válido → valida y muestra el equipo identificado',
        (tester) async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(concedido: true);
      final camara = _CamaraFake();

      await _pantalla(tester, repo: repo, permiso: permiso, camara: camara);

      // El alumno "escanea" el QR.
      camara.onDetectado!('token-valido');
      await tester.pump(); // → validando (puede verse el spinner)
      await tester.pump(); // → equipo encontrado

      expect(find.byKey(const Key('escaneo_equipo_encontrado')), findsOneWidget);
      expect(
        find.byKey(const Key('escaneo_equipo_identificador')),
        findsOneWidget,
      );
      expect(find.text('LT-101'), findsOneWidget);
      expect(
        find.byKey(const Key('escaneo_equipo_ubicacion')),
        findsOneWidget,
      );
      expect(find.text('Ubicación: Lab de redes'), findsOneWidget);
      expect(repo.tokens, ['token-valido']);
    });

    testWidgets('QR inválido (404) → mensaje de error con opción de reintentar',
        (tester) async {
      final repo = _FakeEquiposRepository(
        error: const NotFoundException('QR no válido o equipo inactivo'),
      );
      final permiso = _FakePermisoCamara(concedido: true);
      final camara = _CamaraFake();

      await _pantalla(tester, repo: repo, permiso: permiso, camara: camara);

      camara.onDetectado!('qr-desconocido');
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('escaneo_error_qr')), findsOneWidget);
      expect(
        find.byKey(const Key('escaneo_error_mensaje')),
        findsOneWidget,
      );
      expect(
        find.text('QR no válido o equipo inactivo'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('escaneo_reintentar_qr')), findsOneWidget);

      // Reintentar → vuelve a la cámara.
      await tester.tap(find.byKey(const Key('escaneo_reintentar_qr')));
      await tester.pump();

      expect(find.byKey(const Key('camara_fake')), findsOneWidget);
      expect(find.byKey(const Key('escaneo_error_qr')), findsNothing);
    });

    testWidgets('"Escanear otro código" → vuelve a la cámara tras el éxito',
        (tester) async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final permiso = _FakePermisoCamara(concedido: true);
      final camara = _CamaraFake();

      await _pantalla(tester, repo: repo, permiso: permiso, camara: camara);

      camara.onDetectado!('token-valido');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('escaneo_equipo_encontrado')), findsOneWidget);

      await tester.tap(find.byKey(const Key('escaneo_escanear_otro')));
      await tester.pump();

      expect(find.byKey(const Key('camara_fake')), findsOneWidget);
      expect(
        find.byKey(const Key('escaneo_equipo_encontrado')),
        findsNothing,
      );
    });

    testWidgets('estado "validando" muestra el indicador de progreso',
        (tester) async {
      final repo = _FakeEquiposRepository(equipo: equipo);
      final pendiente = Completer<Equipo>();
      repo.espera = pendiente;
      final permiso = _FakePermisoCamara(concedido: true);
      final camara = _CamaraFake();

      await _pantalla(tester, repo: repo, permiso: permiso, camara: camara);

      camara.onDetectado!('token-valido');
      await tester.pump(); // validando: el backend aún no responde

      expect(
        find.byKey(const Key('escaneo_validando_spinner')),
        findsOneWidget,
      );
      expect(find.text('Validando código…'), findsOneWidget);

      // El backend responde → equipo identificado.
      pendiente.complete(equipo);
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('escaneo_equipo_encontrado')),
        findsOneWidget,
      );
    });
  });
}

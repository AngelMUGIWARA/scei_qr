import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/obtener_equipo_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/obtener_imagen_qr_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/regenerar_qr_usecase.dart';
import 'package:scei_qr/features/equipos/presentation/screens/detalle_equipo_screen.dart';

class FakeEquiposRepository implements EquiposRepository {
  FakeEquiposRepository({this.equipo, this.errorQr, this.errorRegenerar});

  Equipo? equipo;
  Object? errorQr;
  Object? errorRegenerar;
  int imagenesQr = 0;
  int regeneraciones = 0;

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async {
    if (equipo == null) throw Exception('Equipo no encontrado');
    return equipo!;
  }

  @override
  Future<Uint8List> obtenerImagenQr(int id) async {
    imagenesQr++;
    if (errorQr != null) throw errorQr!;
    return _png;
  }

  @override
  Future<Equipo> resolverQr(String qrToken) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> regenerarQr(int id) async {
    regeneraciones++;
    if (errorRegenerar != null) throw errorRegenerar!;
    final actual = equipo!;
    equipo = actual.copyWith(qrToken: 'qr-token-nuevo');
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

/// PNG 1x1 válido para Image.memory.
final Uint8List _png = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const equipo = Equipo(
  id: 12,
  identificador: 'PC-001',
  nombre: 'Equipo de laboratorio',
  descripcion: 'Dell OptiPlex',
  ubicacion: 'Fila A',
  activo: true,
  qrToken: 'qr-token-1',
);

void main() {
  Future<FakeEquiposRepository> abrirPantalla(
    WidgetTester tester, {
    FakeEquiposRepository? repo,
  }) async {
    final repository = repo ?? FakeEquiposRepository(equipo: equipo);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('abrir_detalle'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DetalleEquipoScreen(
                      equipoId: equipo.id,
                      equipoInicial: equipo,
                      obtenerEquipoUseCase: ObtenerEquipoUseCase(repository),
                      obtenerImagenQrUseCase: ObtenerImagenQrUseCase(
                        repository,
                      ),
                      regenerarQrUseCase: RegenerarQrUseCase(repository),
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('abrir_detalle')));
    await tester.pumpAndSettle();
    return repository;
  }

  group('DetalleEquipoScreen — HU-AD-06', () {
    testWidgets('muestra los datos del equipo', (tester) async {
      await abrirPantalla(tester);

      expect(find.text('Detalle del equipo'), findsOneWidget);
      expect(find.byKey(const Key('detalle_equipo_identificador')), findsOneWidget);
      expect(find.text('PC-001'), findsOneWidget);
      expect(find.text('Fila A'), findsOneWidget);
      expect(find.text('Dell OptiPlex'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('visualiza el QR descargado del backend', (tester) async {
      final repo = await abrirPantalla(tester);

      expect(find.byKey(const Key('detalle_equipo_qr_imagen')), findsOneWidget);
      expect(repo.imagenesQr, 1);
      expect(find.text('Código QR'), findsOneWidget);
    });

    testWidgets('regenerar pide confirmación y cancela sin llamar al repo', (
      tester,
    ) async {
      final repo = await abrirPantalla(tester);

      final boton = find.byKey(const Key('detalle_equipo_regenerar_qr'));
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('regenerar_qr_dialog')), findsOneWidget);
      expect(
        find.text(
          'Se generará un código QR nuevo para este equipo. El código '
          'anterior dejará de ser válido y no podrá escanearse.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('regenerar_qr_cancelar')));
      await tester.pumpAndSettle();

      expect(repo.regeneraciones, 0);
      expect(find.byKey(const Key('regenerar_qr_dialog')), findsNothing);
    });

    testWidgets('regenerar confirma, invalida el anterior y lo informa', (
      tester,
    ) async {
      final repo = await abrirPantalla(tester);

      final boton = find.byKey(const Key('detalle_equipo_regenerar_qr'));
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('regenerar_qr_confirmar')));
      await tester.pumpAndSettle();

      expect(repo.regeneraciones, 1);
      // CA: se informa al administrador que el QR anterior dejó de ser válido.
      expect(find.byKey(const Key('regenerar_qr_exito_dialog')), findsOneWidget);
      expect(find.text('QR regenerado'), findsOneWidget);
      expect(
        find.text(
          'El código QR anterior dejó de ser válido. Muestra el nuevo '
          'código QR al equipo.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('regenerar_qr_exito_aceptar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('regenerar_qr_exito_dialog')), findsNothing);
      // El QR mostrado se recargó tras la regeneración.
      expect(repo.imagenesQr, 2);
    });

    testWidgets('un fallo al regenerar muestra aviso sin marcar invalidación', (
      tester,
    ) async {
      final repo = await abrirPantalla(
        tester,
        repo: FakeEquiposRepository(
          equipo: equipo,
          errorRegenerar: Exception('boom'),
        ),
      );

      final boton = find.byKey(const Key('detalle_equipo_regenerar_qr'));
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('regenerar_qr_confirmar')));
      await tester.pumpAndSettle();

      expect(repo.regeneraciones, 1);
      expect(find.byKey(const Key('regenerar_qr_exito_dialog')), findsNothing);
      expect(
        find.byKey(const Key('regenerar_qr_error_snackbar')),
        findsOneWidget,
      );
      expect(find.text('No se pudo regenerar el QR. Inténtalo de nuevo.'), findsOneWidget);
    });

    testWidgets('error al cargar el QR ofrece reintentar sin bloquear', (
      tester,
    ) async {
      final repo = await abrirPantalla(
        tester,
        repo: FakeEquiposRepository(
          equipo: equipo,
          errorQr: Exception('sin red'),
        ),
      );

      expect(find.byKey(const Key('detalle_equipo_qr_error')), findsOneWidget);
      expect(find.byKey(const Key('detalle_equipo_qr_reintentar')), findsOneWidget);
      // Los datos del equipo siguen visibles.
      expect(find.text('PC-001'), findsOneWidget);

      repo.errorQr = null;
      await tester.tap(find.byKey(const Key('detalle_equipo_qr_reintentar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('detalle_equipo_qr_error')), findsNothing);
      expect(find.byKey(const Key('detalle_equipo_qr_imagen')), findsOneWidget);
    });
  });
}

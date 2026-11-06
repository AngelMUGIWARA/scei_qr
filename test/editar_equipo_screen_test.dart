import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/actualizar_equipo_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/obtener_equipo_usecase.dart';
import 'package:scei_qr/features/equipos/presentation/screens/editar_equipo_screen.dart';

class FakeEquiposRepository implements EquiposRepository {
  FakeEquiposRepository(this.equipo);

  Equipo equipo;
  int actualizaciones = 0;
  SolicitudEdicionEquipo? ultimaSolicitud;

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async => equipo;

  @override
  Future<Equipo> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async {
    actualizaciones++;
    ultimaSolicitud = solicitud;
    equipo = equipo.copyWith(
      identificador: solicitud.codigoNormalizado,
      nombre: solicitud.nombreEfectivo,
      descripcion: solicitud.descripcionNormalizada.isEmpty
          ? null
          : solicitud.descripcionNormalizada,
      ubicacion: solicitud.ubicacionNormalizada,
    );
    return equipo;
  }

  @override
  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  }) async => throw UnimplementedError();

  @override
  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo}) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> regenerarQr(int id) async => throw UnimplementedError();

  @override
  Future<Uint8List> obtenerImagenQr(int id) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> resolverQr(String qrToken) async =>
      throw UnimplementedError();
}

const equipo = Equipo(
  id: 1,
  identificador: 'PC-001',
  nombre: 'Equipo de laboratorio',
  descripcion: 'Dell OptiPlex',
  ubicacion: 'Fila A',
  activo: true,
);

void main() {
  Future<FakeEquiposRepository> abrirPantalla(WidgetTester tester) async {
    final repo = FakeEquiposRepository(equipo);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                key: const Key('abrir_editar'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => EditarEquipoScreen(
                      equipoId: equipo.id,
                      equipoInicial: equipo,
                      obtenerEquipoUseCase: ObtenerEquipoUseCase(repo),
                      actualizarEquipoUseCase: ActualizarEquipoUseCase(repo),
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

    await tester.tap(find.byKey(const Key('abrir_editar')));
    await tester.pumpAndSettle();
    return repo;
  }

  group('EditarEquipoScreen - HU-AD-05', () {
    testWidgets('precarga los datos actuales del equipo', (tester) async {
      await abrirPantalla(tester);

      expect(find.text('Editar equipo'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('editar_equipo_codigo_field')),
            )
            .controller
            ?.text,
        'PC-001',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('editar_equipo_nombre_field')),
            )
            .controller
            ?.text,
        'Equipo de laboratorio',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('editar_equipo_ubicacion_field')),
            )
            .controller
            ?.text,
        'Fila A',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('editar_equipo_descripcion_field')),
            )
            .controller
            ?.text,
        'Dell OptiPlex',
      );
    });

    testWidgets('guarda los cambios y regresa al listado', (tester) async {
      final repo = await abrirPantalla(tester);

      await tester.enterText(
        find.byKey(const Key('editar_equipo_nombre_field')),
        'Equipo de diseño',
      );
      await tester.enterText(
        find.byKey(const Key('editar_equipo_ubicacion_field')),
        'Fila B, Mesa 1',
      );
      await tester.enterText(
        find.byKey(const Key('editar_equipo_descripcion_field')),
        'HP EliteDesk',
      );
      await tester.tap(find.byKey(const Key('editar_equipo_guardar')));
      await tester.pumpAndSettle();

      expect(repo.actualizaciones, 1);
      expect(repo.ultimaSolicitud!.codigoNormalizado, 'PC-001');
      expect(repo.ultimaSolicitud!.nombreEfectivo, 'Equipo de diseño');
      expect(repo.ultimaSolicitud!.ubicacionNormalizada, 'Fila B, Mesa 1');
      expect(
        find.byKey(const Key('equipo_actualizado_dialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('equipo_actualizado_aceptar')));
      await tester.pumpAndSettle();

      expect(find.text('Editar equipo'), findsNothing);
      expect(find.byKey(const Key('abrir_editar')), findsOneWidget);
    });

    testWidgets('valida identificador y ubicación obligatorios', (
      tester,
    ) async {
      final repo = await abrirPantalla(tester);

      await tester.enterText(
        find.byKey(const Key('editar_equipo_codigo_field')),
        '',
      );
      await tester.enterText(
        find.byKey(const Key('editar_equipo_ubicacion_field')),
        '',
      );
      await tester.tap(find.byKey(const Key('editar_equipo_guardar')));
      await tester.pumpAndSettle();

      expect(repo.actualizaciones, 0);
      expect(
        find.text('El identificador del equipo es obligatorio'),
        findsOneWidget,
      );
      expect(
        find.text('La ubicación dentro del laboratorio es obligatoria'),
        findsOneWidget,
      );
    });
  });
}

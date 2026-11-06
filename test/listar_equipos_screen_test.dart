import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/cambiar_estado_equipo_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/listar_equipos_usecase.dart';
import 'package:scei_qr/features/equipos/presentation/screens/listar_equipos_screen.dart';

class FakeEquiposRepository implements EquiposRepository {
  FakeEquiposRepository(this.equipos);

  List<Equipo> equipos;
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
    final texto = q?.trim().toLowerCase() ?? '';
    final lugar = ubicacion?.trim().toLowerCase() ?? '';
    return equipos
        .where((equipo) {
          final coincideTexto =
              texto.isEmpty ||
              equipo.identificador.toLowerCase().contains(texto) ||
              equipo.nombreVisible.toLowerCase().contains(texto) ||
              (equipo.descripcion ?? '').toLowerCase().contains(texto);
          final coincideUbicacion =
              lugar.isEmpty || equipo.ubicacion.toLowerCase().contains(lugar);
          final coincideEstado = activo == null || equipo.activo == activo;
          return coincideTexto && coincideUbicacion && coincideEstado;
        })
        .toList(growable: false);
  }

  @override
  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo}) async {
    ultimoEstadoSolicitado = activo;
    final actual = equipos.firstWhere((equipo) => equipo.id == id);
    final actualizado = actual.copyWith(activo: activo);
    equipos = [
      for (final equipo in equipos)
        if (equipo.id == id) actualizado else equipo,
    ];
    return actualizado;
  }

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async =>
      equipos.firstWhere((equipo) => equipo.id == id);

  @override
  Future<Equipo> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async {
    final actual = equipos.firstWhere((equipo) => equipo.id == id);
    final actualizado = actual.copyWith(
      identificador: solicitud.codigoNormalizado,
      nombre: solicitud.nombreEfectivo,
      descripcion: solicitud.descripcionNormalizada.isEmpty
          ? null
          : solicitud.descripcionNormalizada,
      ubicacion: solicitud.ubicacionNormalizada,
    );
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
  Future<Equipo> regenerarQr(int id) async => throw UnimplementedError();

  @override
  Future<Uint8List> obtenerImagenQr(int id) async => _pngDetalle;
}

/// PNG 1x1 válido para Image.memory en el detalle (HU-AD-06).
final Uint8List _pngDetalle = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

const activo = Equipo(
  id: 1,
  identificador: 'PC-001',
  nombre: 'Equipo de laboratorio',
  descripcion: 'Dell OptiPlex',
  ubicacion: 'Fila A',
  activo: true,
);

const inactivo = Equipo(
  id: 2,
  identificador: 'PC-002',
  nombre: 'Equipo de diseño',
  ubicacion: 'Fila B',
  activo: false,
);

void main() {
  Future<FakeEquiposRepository> pumpPantalla(
    WidgetTester tester, {
    List<Equipo>? equipos,
  }) async {
    final repo = FakeEquiposRepository(equipos ?? [activo, inactivo]);
    await tester.pumpWidget(
      Provider<EquiposRepository>.value(
        value: repo,
        child: MaterialApp(
          home: ListarEquiposScreen(
            listarEquiposUseCase: ListarEquiposUseCase(repo),
            cambiarEstadoEquipoUseCase: CambiarEstadoEquipoUseCase(repo),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  group('ListarEquiposScreen - HU-AD-05', () {
    testWidgets('muestra identificación, ubicación y estado de los equipos', (
      tester,
    ) async {
      await pumpPantalla(tester);

      expect(find.text('Administrar equipos'), findsOneWidget);
      expect(find.text('PC-001'), findsOneWidget);
      expect(find.text('Equipo de laboratorio'), findsOneWidget);
      expect(find.textContaining('Fila A'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
      expect(find.byKey(const Key('equipos_lista')), findsOneWidget);
    });

    testWidgets('busca por texto y filtra por ubicación y estado', (
      tester,
    ) async {
      final repo = await pumpPantalla(tester);

      await tester.enterText(
        find.byKey(const Key('equipos_busqueda_field')),
        'PC-001',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repo.ultimaQ, 'PC-001');
      expect(find.text('PC-002'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('equipos_ubicacion_field')),
        'Fila A',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repo.ultimaUbicacion, 'Fila A');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('equipo_card_1')),
          matching: find.text('PC-001'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Inactivos'));
      await tester.pumpAndSettle();

      expect(repo.ultimoActivo, isFalse);
      expect(find.byKey(const Key('equipos_vacio')), findsOneWidget);
    });

    testWidgets('muestra el estado vacío sin equipos registrados', (
      tester,
    ) async {
      await pumpPantalla(tester, equipos: []);

      expect(find.byKey(const Key('equipos_vacio')), findsOneWidget);
      expect(find.text('Aún no hay equipos registrados'), findsOneWidget);
    });

    testWidgets('da de baja un equipo activo tras confirmar', (tester) async {
      final repo = await pumpPantalla(tester);

      await tester.tap(find.byKey(const ValueKey('equipo_cambiar_estado_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cambiar_estado_dialog')), findsOneWidget);
      expect(find.text('Dar de baja equipo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cambiar_estado_confirmar')));
      await tester.pumpAndSettle();

      expect(repo.ultimoEstadoSolicitado, isFalse);
      expect(find.text('Inactivo'), findsNWidgets(2));
      expect(find.textContaining('dado de baja'), findsOneWidget);
    });

    testWidgets('cancela la baja sin llamar al repositorio', (tester) async {
      final repo = await pumpPantalla(tester);

      await tester.tap(find.byKey(const ValueKey('equipo_cambiar_estado_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cambiar_estado_cancelar')));
      await tester.pumpAndSettle();

      expect(repo.ultimoEstadoSolicitado, isNull);
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('al tocar la tarjeta abre el detalle con el QR (HU-AD-06)', (
      tester,
    ) async {
      await pumpPantalla(tester);

      await tester.tap(find.byKey(const ValueKey('equipo_card_1')));
      await tester.pumpAndSettle();

      expect(find.text('Detalle del equipo'), findsOneWidget);
      expect(find.byKey(const Key('detalle_equipo_qr_imagen')), findsOneWidget);
      expect(find.byKey(const Key('detalle_equipo_regenerar_qr')), findsOneWidget);
    });
  });
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/registrar_equipo_usecase.dart';
import 'package:scei_qr/features/equipos/presentation/screens/registrar_equipo_screen.dart';

class FakeEquiposRepository implements EquiposRepository {
  FakeEquiposRepository({this.alRegistrar});

  Future<Equipo> Function(SolicitudAltaEquipo)? alRegistrar;
  int llamadas = 0;
  SolicitudAltaEquipo? ultimaSolicitud;

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    final handler = alRegistrar;
    if (handler == null) {
      return Equipo(
        id: 12,
        identificador: solicitud.identificadorNormalizado,
        ubicacion: solicitud.ubicacionNormalizada,
        descripcion: solicitud.descripcionNormalizada.isEmpty
            ? null
            : solicitud.descripcionNormalizada,
        activo: true,
      );
    }
    return handler(solicitud);
  }

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
  Future<void> pump(WidgetTester tester, EquiposRepository repository) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegistrarEquipoScreen(
          useCase: RegistrarEquipoUseCase(repository),
        ),
      ),
    );
  }

  Future<void> llenar(
    WidgetTester tester, {
    String identificador = 'LAB-PC-001',
    String laboratorio = 'Laboratorio de Cómputo 1',
    String ubicacion = 'Fila A, Mesa 3',
    String descripcion = 'Dell OptiPlex 3080',
  }) async {
    await tester.enterText(
      find.byKey(const Key('equipo_identificador_field')),
      identificador,
    );
    await tester.enterText(
      find.byKey(const Key('equipo_laboratorio_field')),
      laboratorio,
    );
    await tester.enterText(
      find.byKey(const Key('equipo_ubicacion_field')),
      ubicacion,
    );
    await tester.enterText(
      find.byKey(const Key('equipo_descripcion_field')),
      descripcion,
    );
  }

  Future<void> enviar(WidgetTester tester) async {
    final boton = find.byKey(const Key('registrar_equipo_button'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  group('RegistrarEquipoScreen - HU-AD-04', () {
    testWidgets('muestra los 4 campos del alta y el botón', (tester) async {
      await pump(tester, FakeEquiposRepository());

      expect(find.text('Identificador del equipo'), findsOneWidget);
      expect(find.text('Laboratorio'), findsOneWidget);
      expect(find.text('Ubicación dentro del laboratorio'), findsOneWidget);
      expect(find.text('Descripción (marca o modelo)'), findsOneWidget);
      expect(find.byKey(const Key('registrar_equipo_button')), findsOneWidget);
    });

    testWidgets('valida los campos obligatorios vacíos antes de enviar', (
      tester,
    ) async {
      final repo = FakeEquiposRepository();
      await pump(tester, repo);

      await enviar(tester);

      expect(
        find.text('El identificador del equipo es obligatorio'),
        findsOneWidget,
      );
      expect(find.text('El laboratorio es obligatorio'), findsOneWidget);
      expect(
        find.text('La ubicación dentro del laboratorio es obligatoria'),
        findsOneWidget,
      );
      expect(repo.llamadas, 0);
    });

    testWidgets('la descripción es opcional: registra sin ella', (
      tester,
    ) async {
      final repo = FakeEquiposRepository();
      await pump(tester, repo);

      await llenar(tester, descripcion: '');
      await enviar(tester);

      expect(find.byKey(const Key('equipo_registrado_dialog')), findsOneWidget);
      expect(repo.llamadas, 1);
      expect(repo.ultimaSolicitud!.descripcion, isEmpty);
    });

    testWidgets('registra el equipo con estado Activo y muestra confirmación', (
      tester,
    ) async {
      final repo = FakeEquiposRepository();
      await pump(tester, repo);

      await llenar(tester);
      await enviar(tester);

      expect(find.byKey(const Key('equipo_registrado_dialog')), findsOneWidget);
      expect(find.text('Equipo registrado'), findsOneWidget);
      expect(find.textContaining('Activo'), findsOneWidget);
      expect(repo.llamadas, 1);
      expect(repo.ultimaSolicitud!.identificador, 'LAB-PC-001');
      expect(repo.ultimaSolicitud!.laboratorio, 'Laboratorio de Cómputo 1');
      expect(repo.ultimaSolicitud!.ubicacion, 'Fila A, Mesa 3');
      expect(repo.ultimaSolicitud!.descripcion, 'Dell OptiPlex 3080');

      await tester.tap(find.byKey(const Key('equipo_registrado_aceptar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('equipo_registrado_dialog')), findsNothing);
      expect(find.text('LAB-PC-001'), findsNothing);
    });

    testWidgets('muestra el error del servidor cuando el identificador ya '
        'existe', (tester) async {
      final repo = FakeEquiposRepository(
        alRegistrar: (_) async => throw const ConflictException(
          'El código "LAB-PC-001" ya está registrado',
          campo: 'identificador',
        ),
      );
      await pump(tester, repo);

      await llenar(tester);
      await enviar(tester);

      expect(find.byKey(const Key('registrar_equipo_error')), findsOneWidget);
      expect(
        find.text('El código "LAB-PC-001" ya está registrado'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('equipo_registrado_dialog')), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/incidencias/domain/repositories/incidencias_repository.dart';
import 'package:scei_qr/features/incidencias/presentation/screens/reportar_incidencia_screen.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';
import 'package:scei_qr/features/usos/domain/usecases/finalizar_uso_usecase.dart';
import 'package:scei_qr/features/usos/domain/usecases/obtener_uso_activo_usecase.dart';
import 'package:scei_qr/features/usos/presentation/widgets/uso_activo_card.dart';

import 'fakes_incidencias.dart';

class _FakeUsosRepository implements UsosRepository {
  Uso? activo;
  Uso? finalizado;
  Object? errorFinalizar;
  int consultas = 0;

  @override
  Future<Uso> iniciarUso(String qrToken) async => throw UnimplementedError();

  @override
  Future<Uso?> obtenerUsoActivo() async {
    consultas++;
    return activo;
  }

  @override
  Future<Uso> finalizarUso(int usoId) async {
    if (errorFinalizar != null) throw errorFinalizar!;
    activo = null;
    return finalizado!;
  }
}

const _equipo = Equipo(
  id: 12,
  identificador: 'LAB-PC-001',
  nombre: 'PC de la fila A',
  ubicacion: 'Fila A, Mesa 3',
  laboratorio: 'Laboratorio de Cómputo 1',
  descripcion: 'Dell OptiPlex',
  activo: true,
);

final _inicio = DateTime.utc(2026, 11, 8, 15, 30);
final _fin = DateTime.utc(2026, 11, 8, 17, 5);

final _activo = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: _inicio,
  estado: EstadoUso.activo,
  equipo: _equipo,
);

final _finalizado = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: _inicio,
  fin: _fin,
  estado: EstadoUso.finalizado,
  equipo: _equipo,
);

Widget _card(_FakeUsosRepository repo) => UsoActivoCard(
  obtenerUsoActivoUseCase: ObtenerUsoActivoUseCase(repo),
  finalizarUsoUseCase: FinalizarUsoUseCase(repo),
);

/// Uso activo cuya respuesta no trae el equipo embebido.
final _activoSinEquipo = Uso(
  id: 6,
  alumnoId: 9,
  equipoId: 13,
  inicio: _inicio,
  estado: EstadoUso.activo,
);

Future<void> _pantalla(WidgetTester tester, _FakeUsosRepository repo) async {
  await tester.pumpWidget(
    MultiProvider(
      // HU-AL-06: el formulario de reporte resuelve su repositorio aquí.
      providers: [
        Provider<IncidenciasRepository>.value(
          value: FakeIncidenciasRepository(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: ListView(children: [_card(repo)])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _botonFinalizar = find.byKey(const Key('uso_activo_finalizar'));

void main() {
  group('UsoActivoCard — HU-AL-04', () {
    testWidgets('con uso activo (p. ej. al reabrir la app) muestra '
        '"Finalizar uso"', (tester) async {
      final repo = _FakeUsosRepository()..activo = _activo;

      await _pantalla(tester, repo);

      expect(repo.consultas, 1);
      expect(_botonFinalizar, findsOneWidget);
      expect(find.text('Finalizar uso'), findsOneWidget);
      expect(find.text('Equipo: LAB-PC-001'), findsOneWidget);
    });

    testWidgets('sin uso activo no muestra el botón', (tester) async {
      await _pantalla(tester, _FakeUsosRepository());

      expect(_botonFinalizar, findsNothing);
      expect(find.text('Finalizar uso'), findsNothing);
    });

    testWidgets('al finalizar muestra el resumen con los 4 datos, en hora '
        'local, y sin laboratorio', (tester) async {
      final repo = _FakeUsosRepository()
        ..activo = _activo
        ..finalizado = _finalizado;
      await _pantalla(tester, repo);

      await tester.tap(_botonFinalizar);
      await tester.pumpAndSettle();

      expect(_botonFinalizar, findsNothing);
      expect(find.byKey(const Key('uso_activo_resumen')), findsOneWidget);
      expect(find.text('Equipo: LAB-PC-001'), findsOneWidget);
      expect(
        find.text('Inicio: ${formatearFechaHoraLocal(_inicio)}'),
        findsOneWidget,
      );
      expect(
        find.text('Fin: ${formatearFechaHoraLocal(_fin)}'),
        findsOneWidget,
      );
      expect(find.text('Duración: 1 h 35 min'), findsOneWidget);

      // Solo esos 4 datos: ni laboratorio, ni ubicación, ni nombre.
      expect(find.textContaining('Laboratorio de Cómputo 1'), findsNothing);
      expect(find.textContaining('Fila A, Mesa 3'), findsNothing);
      expect(find.textContaining('PC de la fila A'), findsNothing);
      expect(find.textContaining('Dell OptiPlex'), findsNothing);
    });

    testWidgets('sin conexión al finalizar: mensaje claro y el botón sigue '
        'disponible', (tester) async {
      final repo = _FakeUsosRepository()
        ..activo = _activo
        ..errorFinalizar = const NetworkException();
      await _pantalla(tester, repo);

      await tester.tap(_botonFinalizar);
      await tester.pumpAndSettle();

      expect(find.text(const NetworkException().message), findsOneWidget);
      expect(_botonFinalizar, findsOneWidget);
      expect(find.text('Equipo: LAB-PC-001'), findsOneWidget);
    });

    testWidgets('409 al finalizar: avisa y oculta el botón', (tester) async {
      final repo = _FakeUsosRepository()
        ..activo = _activo
        ..errorFinalizar = const ConflictException('El uso ya fue finalizado');
      await _pantalla(tester, repo);

      await tester.tap(_botonFinalizar);
      await tester.pumpAndSettle();

      expect(find.text('El uso ya fue finalizado'), findsOneWidget);
      expect(_botonFinalizar, findsNothing);
    });

    testWidgets('vuelve a consultar al regresar de otra pantalla (p. ej. '
        'después de registrar el uso)', (tester) async {
      final repo = _FakeUsosRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ListView(
                children: [
                  _card(repo),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(body: Text('Registro')),
                      ),
                    ),
                    child: const Text('Ir a registrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_botonFinalizar, findsNothing);

      await tester.tap(find.text('Ir a registrar'));
      await tester.pumpAndSettle();
      repo.activo = _activo; // HU-AL-03 registró el uso en la otra pantalla.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(repo.consultas, 2);
      expect(_botonFinalizar, findsOneWidget);
    });
  });

  group('UsoActivoCard — HU-AL-06 (reportar incidencia)', () {
    final botonReportar = find.byKey(
      const Key('uso_activo_reportar_incidencia'),
    );

    testWidgets('con uso activo aparece el botón "Reportar incidencia"', (
      tester,
    ) async {
      final repo = _FakeUsosRepository()..activo = _activo;

      await _pantalla(tester, repo);

      expect(botonReportar, findsOneWidget);
      expect(find.text('Reportar incidencia'), findsOneWidget);
    });

    testWidgets('sin uso activo no aparece el botón de reportar', (
      tester,
    ) async {
      await _pantalla(tester, _FakeUsosRepository());

      expect(botonReportar, findsNothing);
      expect(find.text('Reportar incidencia'), findsNothing);
    });

    testWidgets('si el uso activo no trae el equipo no se ofrece reportar', (
      tester,
    ) async {
      final repo = _FakeUsosRepository()..activo = _activoSinEquipo;

      await _pantalla(tester, repo);

      expect(find.byKey(const Key('uso_activo_en_curso')), findsOneWidget);
      expect(botonReportar, findsNothing);
    });

    testWidgets('al tocarlo abre el formulario con el equipo del uso', (
      tester,
    ) async {
      final repo = _FakeUsosRepository()..activo = _activo;
      await _pantalla(tester, repo);

      await tester.tap(botonReportar);
      await tester.pumpAndSettle();

      expect(find.byType(ReportarIncidenciaScreen), findsOneWidget);
      expect(find.byKey(const Key('reporte_formulario')), findsOneWidget);
      expect(
        find.byKey(const Key('reporte_equipo_identificador')),
        findsOneWidget,
      );
      expect(find.text('LAB-PC-001'), findsOneWidget);
      expect(find.text('Fila A, Mesa 3'), findsOneWidget);
      // El equipo es solo lectura: el único campo editable es la descripción.
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('al finalizar el uso desaparece (solo queda el resumen)', (
      tester,
    ) async {
      final repo = _FakeUsosRepository()
        ..activo = _activo
        ..finalizado = _finalizado;
      await _pantalla(tester, repo);

      expect(botonReportar, findsOneWidget);

      await tester.tap(find.byKey(const Key('uso_activo_finalizar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('uso_activo_resumen')), findsOneWidget);
      expect(botonReportar, findsNothing);
      expect(find.text('Reportar incidencia'), findsNothing);
    });
  });

  group('formatearDuracion — HU-AL-04', () {
    test('horas y minutos', () {
      expect(
        formatearDuracion(const Duration(hours: 2, minutes: 5)),
        '2 h 05 min',
      );
    });

    test('solo minutos', () {
      expect(formatearDuracion(const Duration(minutes: 45)), '45 min');
    });

    test('menos de un minuto', () {
      expect(formatearDuracion(const Duration(seconds: 30)), '30 s');
    });
  });
}

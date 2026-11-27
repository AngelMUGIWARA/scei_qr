import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/incidencia.dart';
import 'package:scei_qr/features/incidencias/domain/usecases/reportar_incidencia_usecase.dart';
import 'package:scei_qr/features/incidencias/presentation/screens/reportar_incidencia_screen.dart';

import 'fakes_incidencias.dart';

const _botonEnviar = Key('reporte_boton_enviar');
const _campoDescripcion = Key('reporte_descripcion');
const _chipSoftware = Key('reporte_tipo_software');

/// Misma fórmula que usa la pantalla para la fecha del resumen.
String _fechaEsperada() {
  final fecha = DateTime.utc(2026, 11, 25, 10, 30).toLocal();
  String dos(int valor) => valor.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}

Future<void> _pantalla(
  WidgetTester tester,
  FakeIncidenciasRepository repo,
) async {
  // Superficie amplia para que el formulario completo quepa sin scroll.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ReportarIncidenciaScreen(
        equipo: equipoDePrueba,
        useCase: ReportarIncidenciaUseCase(repo),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byKey(_campoDescripcion), texto);
  await tester.pump();
}

Future<void> _elegirSoftware(WidgetTester tester) async {
  await tester.tap(find.byKey(_chipSoftware));
  await tester.pump();
}

/// Escribe la descripción y elige un tipo: el mínimo para poder enviar.
Future<void> _listoParaEnviar(
  WidgetTester tester, {
  String texto = 'La pantalla parpadea',
}) async {
  await _escribir(tester, texto);
  await _elegirSoftware(tester);
}

Future<void> _enviar(WidgetTester tester) async {
  await tester.tap(find.byKey(_botonEnviar));
  await tester.pumpAndSettle();
}

void main() {
  group('ReportarIncidenciaScreen — HU-AL-06 (formulario)', () {
    testWidgets('el botón de enviar está deshabilitado sin descripción', (
      tester,
    ) async {
      await _pantalla(tester, FakeIncidenciasRepository());

      expect(
        tester.widget<FilledButton>(find.byKey(_botonEnviar)).onPressed,
        isNull,
      );

      // Solo espacios: sigue deshabilitado.
      await _escribir(tester, '     ');
      expect(
        tester.widget<FilledButton>(find.byKey(_botonEnviar)).onPressed,
        isNull,
      );

      await _escribir(tester, 'La pantalla parpadea');
      expect(
        tester.widget<FilledButton>(find.byKey(_botonEnviar)).onPressed,
        isNotNull,
      );
    });

    testWidgets('el tipo de problema empieza sin selección y se puede elegir', (
      tester,
    ) async {
      await _pantalla(tester, FakeIncidenciasRepository());

      for (final tipo in TipoProblema.values) {
        final chip = tester.widget<ChoiceChip>(
          find.byKey(Key('reporte_tipo_${tipo.name}')),
        );
        expect(chip.selected, isFalse, reason: 'venía preseleccionado $tipo');
      }

      await _elegirSoftware(tester);

      expect(
        tester.widget<ChoiceChip>(find.byKey(_chipSoftware)).selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('reporte_tipo_hardware')))
            .selected,
        isFalse,
      );
    });

    testWidgets('sin tipo seleccionado no envía y avisa que es obligatorio', (
      tester,
    ) async {
      final repo = FakeIncidenciasRepository();
      await _pantalla(tester, repo);

      await _escribir(tester, 'No enciende el monitor');
      await _enviar(tester);

      expect(repo.llamadas, 0);
      expect(find.byKey(const Key('reporte_error_tipo')), findsOneWidget);
      expect(find.text('Elige el tipo de problema.'), findsOneWidget);
      expect(find.byKey(const Key('reporte_formulario')), findsOneWidget);
    });

    testWidgets('la descripción tiene un límite de 500 caracteres', (
      tester,
    ) async {
      await _pantalla(tester, FakeIncidenciasRepository());

      final campo = tester.widget<TextFormField>(find.byKey(_campoDescripcion));
      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(_campoDescripcion),
          matching: find.byType(TextField),
        ),
      );

      expect(campo.key, _campoDescripcion);
      expect(textField.maxLength, 500);
    });

    testWidgets('envía el reporte y muestra folio, tipo, estado y fecha', (
      tester,
    ) async {
      final repo = FakeIncidenciasRepository()
        ..incidencia = incidenciaDePrueba(tipo: TipoProblema.software);
      await _pantalla(tester, repo);

      await _listoParaEnviar(tester);
      await _enviar(tester);

      expect(repo.llamadas, 1);
      expect(repo.ultimoEnvio!.equipoId, equipoDePrueba.id);
      expect(repo.ultimoEnvio!.tipo, TipoProblema.software);
      expect(repo.ultimoEnvio!.descripcion, 'La pantalla parpadea');

      expect(find.byKey(const Key('reporte_confirmacion')), findsOneWidget);
      expect(find.byKey(const Key('reporte_folio')), findsOneWidget);
      expect(find.text('INC-000042'), findsOneWidget);
      expect(
        find.textContaining('Equipo: LAB-PC-001', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tipo: Software', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Estado: Pendiente', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(_fechaEsperada(), findRichText: true),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reporte_boton_listo')), findsOneWidget);
    });

    testWidgets('el equipo llega identificado y no se puede cambiar', (
      tester,
    ) async {
      await _pantalla(tester, FakeIncidenciasRepository());

      expect(
        find.byKey(const Key('reporte_equipo_identificador')),
        findsOneWidget,
      );
      expect(find.text('LAB-PC-001'), findsOneWidget);
      expect(find.text('Fila A, Mesa 3'), findsOneWidget);

      // Único campo editable: la descripción.
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('doble toque en enviar hace una sola petición', (tester) async {
      final repo = FakeIncidenciasRepository();
      await _pantalla(tester, repo);
      await _escribir(tester, 'Se traba al abrir');
      await _elegirSoftware(tester);

      await tester.tap(find.byKey(_botonEnviar));
      await tester.tap(find.byKey(_botonEnviar));
      await tester.pumpAndSettle();

      expect(repo.llamadas, 1);
      expect(find.byKey(const Key('reporte_confirmacion')), findsOneWidget);
    });
  });

  group('ReportarIncidenciaScreen — HU-AL-06 (errores)', () {
    testWidgets('sin conexión muestra el error con la opción de reintentar', (
      tester,
    ) async {
      final repo = FakeIncidenciasRepository(error: const NetworkException());
      await _pantalla(tester, repo);

      await _listoParaEnviar(tester);
      await _enviar(tester);

      expect(find.byKey(const Key('reporte_error')), findsOneWidget);
      expect(find.byKey(const Key('reporte_error_mensaje')), findsOneWidget);
      expect(find.text(const NetworkException().message), findsOneWidget);
      expect(find.byKey(const Key('reporte_boton_reintentar')), findsOneWidget);
      expect(
        find.byKey(const Key('reporte_boton_volver_formulario')),
        findsOneWidget,
      );
      expect(repo.llamadas, 1);

      // Reintentar vuelve a enviar los mismos datos.
      repo.error = null;
      await tester.tap(find.byKey(const Key('reporte_boton_reintentar')));
      await tester.pumpAndSettle();

      expect(repo.llamadas, 2);
      expect(find.byKey(const Key('reporte_confirmacion')), findsOneWidget);
    });

    testWidgets('un error del negocio no ofrece reintentar', (tester) async {
      final repo = FakeIncidenciasRepository(
        error: const NotFoundException(
          'El equipo no existe o está dado de baja.',
        ),
      );
      await _pantalla(tester, repo);

      await _listoParaEnviar(tester);
      await _enviar(tester);

      expect(find.byKey(const Key('reporte_error')), findsOneWidget);
      expect(
        find.text('El equipo no existe o está dado de baja.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reporte_boton_reintentar')), findsNothing);
      expect(
        find.byKey(const Key('reporte_boton_volver_formulario')),
        findsOneWidget,
      );
    });

    testWidgets('"Editar reporte" conserva el texto escrito y el tipo', (
      tester,
    ) async {
      final repo = FakeIncidenciasRepository(error: const NetworkException());
      await _pantalla(tester, repo);

      await _escribir(tester, 'El teclado no responde');
      await _elegirSoftware(tester);
      await _enviar(tester);
      expect(find.byKey(const Key('reporte_error')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('reporte_boton_volver_formulario')),
      );
      await tester.pumpAndSettle();

      // Regresión: el formulario se recrea pero conserva lo capturado.
      expect(find.byKey(const Key('reporte_formulario')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(_campoDescripcion))
            .controller!
            .text,
        'El teclado no responde',
      );
      expect(
        tester.widget<FilledButton>(find.byKey(_botonEnviar)).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<ChoiceChip>(find.byKey(_chipSoftware)).selected,
        isTrue,
      );

      // Y el envío posterior sí sale.
      repo.error = null;
      await _enviar(tester);
      expect(repo.llamadas, 2);
      expect(find.byKey(const Key('reporte_confirmacion')), findsOneWidget);
    });
  });
}

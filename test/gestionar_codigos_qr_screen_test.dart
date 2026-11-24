import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/printing/impresion_service.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/descargar_etiqueta_qr_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/descargar_etiquetas_lote_usecase.dart';
import 'package:scei_qr/features/equipos/domain/usecases/listar_equipos_usecase.dart';
import 'package:scei_qr/features/equipos/presentation/screens/gestionar_codigos_qr_screen.dart';

final _pdf = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]);

class _FakeEquiposRepository implements EquiposRepository {
  _FakeEquiposRepository(this.equipos);

  List<Equipo> equipos;
  String? ultimoLaboratorio;
  String? ultimaUbicacion;
  int etiquetasDescargadas = 0;
  int lotesDescargados = 0;
  Object? errorLote;

  @override
  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    String? laboratorio,
    bool? activo,
  }) async {
    ultimoLaboratorio = laboratorio;
    ultimaUbicacion = ubicacion;
    return equipos;
  }

  @override
  Future<Uint8List> descargarEtiquetaQrPdf(int id) async {
    etiquetasDescargadas++;
    return _pdf;
  }

  @override
  Future<Uint8List> descargarEtiquetasLote({
    String? laboratorio,
    String? ubicacion,
    bool? activo,
  }) async {
    lotesDescargados++;
    if (errorLote != null) throw errorLote!;
    return _pdf;
  }

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async => equipos.first;

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async =>
      throw UnimplementedError();

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

  @override
  Future<Equipo> resolverQr(String qrToken) async => throw UnimplementedError();
}

class _FakeImpresionService implements ImpresionService {
  int impresiones = 0;
  int descargas = 0;
  String? ultimoNombre;

  @override
  Future<void> imprimir(Uint8List pdf, {required String nombre}) async {
    impresiones++;
    ultimoNombre = nombre;
  }

  @override
  Future<void> descargar(Uint8List pdf, {required String nombre}) async {
    descargas++;
    ultimoNombre = nombre;
  }
}

const _equipoA = Equipo(
  id: 1,
  identificador: 'LAB-PC-001',
  nombre: 'PC Dell',
  ubicacion: 'Fila A, Mesa 1',
  laboratorio: 'Laboratorio de Cómputo 1',
  activo: true,
);

const _equipoB = Equipo(
  id: 2,
  identificador: 'LAB-PC-002',
  nombre: 'PC HP',
  ubicacion: 'Fila A, Mesa 2',
  laboratorio: 'Laboratorio de Cómputo 1',
  activo: true,
);

void main() {
  Future<_FakeBundle> abrirPantalla(WidgetTester tester) async {
    final repository = _FakeEquiposRepository([_equipoA, _equipoB]);
    final impresion = _FakeImpresionService();

    await tester.pumpWidget(
      MaterialApp(
        home: GestionarCodigosQrScreen(
          listarEquiposUseCase: ListarEquiposUseCase(repository),
          descargarEtiquetaQrUseCase: DescargarEtiquetaQrUseCase(repository),
          descargarEtiquetasLoteUseCase: DescargarEtiquetasLoteUseCase(
            repository,
          ),
          impresionService: impresion,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return _FakeBundle(repository, impresion);
  }

  testWidgets('HU-AD-07 muestra los equipos y las acciones de etiqueta', (
    tester,
  ) async {
    await abrirPantalla(tester);

    expect(find.text('Códigos QR y etiquetas'), findsOneWidget);
    expect(find.text('LAB-PC-001'), findsOneWidget);
    expect(find.text('LAB-PC-002'), findsOneWidget);
    expect(find.byKey(const Key('etiquetas_descargar_lote')), findsOneWidget);
    expect(find.byKey(const Key('etiquetas_imprimir_lote')), findsOneWidget);
  });

  testWidgets('HU-AD-07 filtra el lote por laboratorio', (tester) async {
    final bundle = await abrirPantalla(tester);

    await tester.enterText(
      find.byKey(const Key('etiquetas_laboratorio_field')),
      'Laboratorio de Cómputo 1',
    );
    await tester.tap(find.byKey(const Key('etiquetas_aplicar_filtros')));
    await tester.pumpAndSettle();

    expect(bundle.repository.ultimoLaboratorio, 'Laboratorio de Cómputo 1');
    expect(find.byKey(const Key('etiquetas_conteo')), findsOneWidget);
  });

  testWidgets('HU-AD-07 descarga el lote como PDF', (tester) async {
    final bundle = await abrirPantalla(tester);

    await tester.enterText(
      find.byKey(const Key('etiquetas_laboratorio_field')),
      'Laboratorio de Cómputo 1',
    );
    await tester.tap(find.byKey(const Key('etiquetas_aplicar_filtros')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('etiquetas_descargar_lote')));
    await tester.pumpAndSettle();

    expect(bundle.repository.lotesDescargados, 1);
    expect(bundle.impresion.descargas, 1);
    expect(
      bundle.impresion.ultimoNombre,
      'etiquetas-laboratorio-de-computo-1.pdf',
    );
    expect(find.byKey(const Key('etiquetas_lote_snackbar')), findsOneWidget);
  });

  testWidgets('HU-AD-07 imprime una etiqueta individual', (tester) async {
    final bundle = await abrirPantalla(tester);

    await tester.tap(find.byKey(const ValueKey('etiqueta_imprimir_1')));
    await tester.pumpAndSettle();

    expect(bundle.repository.etiquetasDescargadas, 1);
    expect(bundle.impresion.impresiones, 1);
    expect(bundle.impresion.ultimoNombre, 'etiqueta-lab-pc-001.pdf');
    expect(find.byKey(const Key('etiquetas_snackbar')), findsOneWidget);
  });

  testWidgets('HU-AD-07 muestra el error del backend al generar el lote', (
    tester,
  ) async {
    final bundle = await abrirPantalla(tester);
    bundle.repository.errorLote = Exception('sin equipos');

    await tester.tap(find.byKey(const Key('etiquetas_descargar_lote')));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudieron descargar las etiquetas.'),
      findsOneWidget,
    );
  });
}

class _FakeBundle {
  _FakeBundle(this.repository, this.impresion);

  final _FakeEquiposRepository repository;
  final _FakeImpresionService impresion;
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/cambiar_estado_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/editar_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/listar_tecnicos_usecase.dart';
import 'package:scei_qr/features/usuarios/presentation/screens/administrar_tecnicos_screen.dart';

import 'fakes_usuarios.dart';

void main() {
  Widget app(FakeUsuariosRepository repo) {
    return MaterialApp(
      home: AdministrarTecnicosScreen(
        listarUseCase: ListarTecnicosUseCase(repo),
        cambiarEstadoUseCase: CambiarEstadoTecnicoUseCase(repo),
        editarUseCase: EditarTecnicoUseCase(repo),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    FakeUsuariosRepository repo,
  ) async {
    await tester.pumpWidget(app(repo));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  group('AdministrarTecnicosScreen - HU-AD-03', () {
    testWidgets('muestra el listado con el estado de cada técnico', (
      tester,
    ) async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());

      await pumpScreen(tester, repo);

      expect(find.text('Carlos Mena'), findsOneWidget);
      expect(find.text('Lucía López'), findsOneWidget);
      expect(find.text('carlos.mena@utez.edu.mx'), findsOneWidget);
      expect(find.text('Usuario: cmena'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Inactivo'), findsOneWidget);
      expect(repo.listarLlamadas, 1);
    });

    testWidgets('busca técnicos por nombre', (tester) async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      await pumpScreen(tester, repo);

      await tester.enterText(
        find.byKey(const Key('buscar_tecnicos_field')),
        'Lucía',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repo.ultimaBusqueda, 'Lucía');
      expect(find.text('Lucía López'), findsOneWidget);
      expect(find.text('Carlos Mena'), findsNothing);
    });

    testWidgets('filtra por técnicos activos e inactivos', (tester) async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      await pumpScreen(tester, repo);

      await tester.tap(find.byKey(const Key('filtro_tecnicos_activos')));
      await tester.pumpAndSettle();

      expect(repo.ultimoFiltroActivo, isTrue);
      expect(find.text('Carlos Mena'), findsOneWidget);
      expect(find.text('Lucía López'), findsNothing);

      await tester.tap(find.byKey(const Key('filtro_tecnicos_inactivos')));
      await tester.pumpAndSettle();

      expect(repo.ultimoFiltroActivo, isFalse);
      expect(find.text('Carlos Mena'), findsNothing);
      expect(find.text('Lucía López'), findsOneWidget);
    });

    testWidgets('muestra el estado vacío cuando no hay técnicos', (
      tester,
    ) async {
      final repo = FakeUsuariosRepository();

      await pumpScreen(tester, repo);

      expect(find.byKey(const Key('tecnicos_vacio')), findsOneWidget);
      expect(find.text('Aún no hay técnicos registrados'), findsOneWidget);
    });

    testWidgets('desactiva un técnico después de confirmar', (tester) async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      await pumpScreen(tester, repo);

      await tester.tap(find.byKey(const Key('tecnico_switch_7')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmar_estado_dialog')), findsOneWidget);
      expect(find.text('Desactivar técnico'), findsOneWidget);
      expect(
        find.textContaining('incidencias atendidas se conservarán'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('confirmar_estado_aceptar')));
      await tester.pumpAndSettle();

      expect(repo.cambiarEstadoLlamadas, 1);
      expect(repo.ultimoId, 7);
      expect(repo.ultimoActivo, isFalse);
      expect(
        tester.widget<Switch>(find.byKey(const Key('tecnico_switch_7'))).value,
        isFalse,
      );

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('reactiva un técnico inactivo después de confirmar', (
      tester,
    ) async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      await pumpScreen(tester, repo);

      await tester.tap(find.byKey(const Key('tecnico_switch_8')));
      await tester.pumpAndSettle();

      expect(find.text('Reactivar técnico'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmar_estado_aceptar')));
      await tester.pumpAndSettle();

      expect(repo.ultimoId, 8);
      expect(repo.ultimoActivo, isTrue);
      expect(
        tester.widget<Switch>(find.byKey(const Key('tecnico_switch_8'))).value,
        isTrue,
      );

      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('cancelar la confirmación no cambia el estado', (tester) async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      await pumpScreen(tester, repo);

      await tester.tap(find.byKey(const Key('tecnico_switch_7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar_estado_cancelar')));
      await tester.pumpAndSettle();

      expect(repo.cambiarEstadoLlamadas, 0);
      expect(
        tester.widget<Switch>(find.byKey(const Key('tecnico_switch_7'))).value,
        isTrue,
      );
    });
  });
}

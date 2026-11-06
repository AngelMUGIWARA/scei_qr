import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/tecnico.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/editar_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/presentation/screens/editar_tecnico_screen.dart';

import 'fakes_usuarios.dart';

void main() {
  Future<void> abrirEditar(
    WidgetTester tester,
    FakeUsuariosRepository repo, {
    Tecnico? tecnico,
  }) async {
    final objetivo = tecnico ?? tecnicoDePrueba();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('abrir_editar'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<Tecnico>(
                    builder: (_) => EditarTecnicoScreen(
                      tecnico: objetivo,
                      useCase: EditarTecnicoUseCase(repo),
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
  }

  Future<void> guardar(WidgetTester tester) async {
    final boton = find.byKey(const Key('editar_tecnico_button'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  String textoCampo(WidgetTester tester, String key) {
    final field = tester.widget<TextFormField>(find.byKey(Key(key)));
    return field.controller?.text ?? '';
  }

  group('EditarTecnicoScreen - HU-AD-03', () {
    testWidgets('precarga los datos de contacto del técnico', (tester) async {
      final repo = FakeUsuariosRepository(tecnicos: [tecnicoDePrueba()]);

      await abrirEditar(tester, repo);

      expect(textoCampo(tester, 'editar_tecnico_nombre_field'), 'Carlos Mena');
      expect(
        textoCampo(tester, 'editar_tecnico_correo_field'),
        'carlos.mena@utez.edu.mx',
      );
      expect(find.text('cmena'), findsOneWidget);
      expect(find.text('Cuenta activa'), findsOneWidget);
    });

    testWidgets('guarda los datos de contacto sin cambiar la contraseña', (
      tester,
    ) async {
      final repo = FakeUsuariosRepository(tecnicos: [tecnicoDePrueba()]);
      await abrirEditar(tester, repo);

      await tester.enterText(
        find.byKey(const Key('editar_tecnico_nombre_field')),
        'Carlos Mena García',
      );
      await tester.enterText(
        find.byKey(const Key('editar_tecnico_correo_field')),
        'Carlos.Garcia@UTEZ.EDU.MX',
      );
      await guardar(tester);

      expect(repo.editarLlamadas, 1);
      expect(repo.ultimoId, 7);
      expect(
        repo.ultimaSolicitudEdicion!.nombreNormalizado,
        'Carlos Mena García',
      );
      expect(
        repo.ultimaSolicitudEdicion!.correoNormalizado,
        'carlos.garcia@utez.edu.mx',
      );
      expect(repo.ultimaSolicitudEdicion!.contrasenaNueva, isNull);
      expect(find.byKey(const Key('abrir_editar')), findsOneWidget);
    });

    testWidgets('restablece la contraseña cuando se captura', (tester) async {
      final repo = FakeUsuariosRepository(tecnicos: [tecnicoDePrueba()]);
      await abrirEditar(tester, repo);

      await tester.enterText(
        find.byKey(const Key('editar_tecnico_password_field')),
        'NuevaPassword123!',
      );
      await tester.enterText(
        find.byKey(const Key('editar_tecnico_confirmacion_field')),
        'NuevaPassword123!',
      );
      await guardar(tester);

      expect(repo.editarLlamadas, 1);
      expect(repo.ultimaSolicitudEdicion!.contrasenaNueva, 'NuevaPassword123!');
    });

    testWidgets('rechaza contraseñas que no coinciden', (tester) async {
      final repo = FakeUsuariosRepository(tecnicos: [tecnicoDePrueba()]);
      await abrirEditar(tester, repo);

      await tester.enterText(
        find.byKey(const Key('editar_tecnico_password_field')),
        'NuevaPassword123!',
      );
      await tester.enterText(
        find.byKey(const Key('editar_tecnico_confirmacion_field')),
        'OtraPassword123!',
      );
      await guardar(tester);

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(repo.editarLlamadas, 0);
    });

    testWidgets('muestra el conflicto del backend', (tester) async {
      final repo = FakeUsuariosRepository(
        tecnicos: [tecnicoDePrueba()],
        alEditar: (_, _) async => throw const ConflictException(
          'El correo ya existe',
          campo: 'correo',
        ),
      );
      await abrirEditar(tester, repo);

      await guardar(tester);

      expect(find.byKey(const Key('editar_tecnico_error')), findsOneWidget);
      expect(find.text('El correo ya existe'), findsOneWidget);
      expect(find.byKey(const Key('abrir_editar')), findsNothing);
    });
  });
}

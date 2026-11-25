import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';
import 'package:scei_qr/features/usos/domain/usecases/registrar_uso_usecase.dart';
import 'package:scei_qr/features/usos/presentation/screens/confirmar_uso_screen.dart';

import 'fakes_usos.dart';

class _FakeUsosRepository implements UsosRepository {
  _FakeUsosRepository({this.uso, this.error});

  Uso? uso;
  Object? error;
  final List<String> tokens = [];

  @override
  Future<Uso> iniciarUso(String qrToken, {String? idempotencyKey}) async {
    tokens.add(qrToken);
    if (error != null) throw error!;
    return uso!;
  }
}

const equipo = Equipo(
  id: 12,
  identificador: 'LAB-PC-001',
  nombre: 'LAB-PC-001',
  ubicacion: 'Fila A, Mesa 3',
  activo: true,
  qrToken: 'qr-token',
);

final usoRegistrado = Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: DateTime.utc(2026, 11, 8, 15, 30),
  estado: EstadoUso.activo,
  equipo: equipo,
);

Future<FakeColaUsosPendientes> _pantalla(
  WidgetTester tester,
  _FakeUsosRepository repo,
) async {
  final cola = FakeColaUsosPendientes();
  await tester.pumpWidget(
    MaterialApp(
      home: ConfirmarUsoScreen(
        equipo: equipo,
        qrToken: 'qr-token',
        registrarUsoUseCase: RegistrarUsoUseCase(repo, cola),
      ),
    ),
  );
  return cola;
}

void main() {
  group('ConfirmarUsoScreen — HU-AL-03', () {
    testWidgets('pide confirmación antes de guardar y muestra el equipo', (
      tester,
    ) async {
      final repo = _FakeUsosRepository(uso: usoRegistrado);
      await _pantalla(tester, repo);

      expect(
        find.byKey(const Key('confirmar_uso_confirmando')),
        findsOneWidget,
      );
      expect(find.text('Equipo identificado'), findsOneWidget);
      expect(find.text('LAB-PC-001'), findsOneWidget);
      expect(find.text('Ubicación: Fila A, Mesa 3'), findsOneWidget);
      expect(find.byKey(const Key('confirmar_uso_confirmar')), findsOneWidget);
      expect(repo.tokens, isEmpty);
    });

    testWidgets('al confirmar guarda y muestra la confirmación visual', (
      tester,
    ) async {
      final repo = _FakeUsosRepository(uso: usoRegistrado);
      await _pantalla(tester, repo);

      await tester.tap(find.byKey(const Key('confirmar_uso_confirmar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmar_uso_registrado')), findsOneWidget);
      expect(find.text('Uso registrado'), findsOneWidget);
      expect(
        find.byKey(const Key('confirmar_uso_registrado_inicio')),
        findsOneWidget,
      );
      expect(find.textContaining('08/11/2026'), findsOneWidget);
      expect(repo.tokens, ['qr-token']);
    });

    testWidgets('sin conexión deja el uso pendiente y lo encola', (
      tester,
    ) async {
      final repo = _FakeUsosRepository(error: const NetworkException());
      final cola = await _pantalla(tester, repo);

      await tester.tap(find.byKey(const Key('confirmar_uso_confirmar')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('confirmar_uso_pendiente')),
        findsOneWidget,
      );
      expect(find.text('Uso pendiente de sincronizar'), findsOneWidget);
      expect(
        find.byKey(const Key('confirmar_uso_pendiente_listo')),
        findsOneWidget,
      );
      expect(cola.items, hasLength(1));
      expect(cola.items.single.qrToken, 'qr-token');
    });

    testWidgets('conflicto 409 muestra el mensaje sin botón de reintentar', (
      tester,
    ) async {
      final repo = _FakeUsosRepository(
        error: const ConflictException(
          'El equipo ya está en uso. Finaliza el uso actual.',
        ),
      );
      await _pantalla(tester, repo);

      await tester.tap(find.byKey(const Key('confirmar_uso_confirmar')));
      await tester.pumpAndSettle();

      expect(
        find.text('El equipo ya está en uso. Finaliza el uso actual.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('confirmar_uso_reintentar')), findsNothing);
      expect(find.byKey(const Key('confirmar_uso_volver')), findsOneWidget);
    });
  });
}

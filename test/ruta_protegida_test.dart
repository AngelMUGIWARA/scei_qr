import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/permiso.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/dominio/sesion.dart';
import 'package:scei_qr/presentacion/acceso/ruta_protegida.dart';

void main() {
  final ahora = DateTime(2026, 10, 23, 12);

  Sesion sesionDe(Rol rol, {DateTime? expiraEn}) => Sesion(
        token: 'token-de-prueba',
        rol: rol,
        expiraEn: expiraEn ?? ahora.add(const Duration(hours: 8)),
        usuarioId: 1,
        username: 'usuario',
        nombreCompleto: 'Usuario de Prueba',
      );

  Widget appCon(Widget child) => MaterialApp(home: child);

  const contenido = Scaffold(body: Text('Contenido protegido'));

  Widget ruta({
    required Sesion? sesion,
    required Permiso permiso,
    Widget child = contenido,
    Widget Function(BuildContext, String)? alRechazar,
  }) =>
      RutaProtegida(
        sesion: sesion,
        permiso: permiso,
        ahora: ahora,
        alRechazar: alRechazar,
        child: child,
      );

  group('RutaProtegida', () {
    testWidgets('muestra el contenido con sesión y permiso válidos',
        (tester) async {
      await tester.pumpWidget(
        appCon(
          ruta(
            sesion: sesionDe(Rol.administrador),
            permiso: Permiso.administrarEquipos,
          ),
        ),
      );

      expect(find.text('Contenido protegido'), findsOneWidget);
      expect(find.text('Acceso restringido'), findsNothing);
    });

    testWidgets('bloquea sin sesión y muestra el motivo', (tester) async {
      await tester.pumpWidget(
        appCon(
          ruta(
            sesion: null,
            permiso: Permiso.registrarUso,
          ),
        ),
      );

      expect(find.text('Contenido protegido'), findsNothing);
      expect(find.text('Acceso restringido'), findsOneWidget);
      expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    });

    testWidgets('bloquea una sesión vencida', (tester) async {
      await tester.pumpWidget(
        appCon(
          ruta(
            sesion: sesionDe(
              Rol.alumno,
              expiraEn: ahora.subtract(const Duration(minutes: 1)),
            ),
            permiso: Permiso.registrarUso,
          ),
        ),
      );

      expect(find.text('Contenido protegido'), findsNothing);
      expect(
        find.text('Tu sesión expiró, inicia sesión de nuevo'),
        findsOneWidget,
      );
    });

    testWidgets('bloquea un permiso ajeno al rol', (tester) async {
      await tester.pumpWidget(
        appCon(
          ruta(
            sesion: sesionDe(Rol.alumno),
            permiso: Permiso.administrarEquipos,
          ),
        ),
      );

      expect(find.text('Contenido protegido'), findsNothing);
      expect(find.text('No tienes permiso para esta acción'), findsOneWidget);
    });

    testWidgets('permite personalizar la pantalla de rechazo', (tester) async {
      await tester.pumpWidget(
        appCon(
          ruta(
            sesion: sesionDe(Rol.alumno),
            permiso: Permiso.administrarEquipos,
            alRechazar: (_, motivo) => Scaffold(body: Text('Rechazo: $motivo')),
          ),
        ),
      );

      expect(find.text('Rechazo: No tienes permiso para esta acción'),
          findsOneWidget);
      expect(find.text('Acceso restringido'), findsNothing);
    });

    testWidgets('ofrece volver cuando la ruta fue empujada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ruta(
                      sesion: sesionDe(Rol.alumno),
                      permiso: Permiso.administrarEquipos,
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Acceso restringido'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);
    });
  });
}

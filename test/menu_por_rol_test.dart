import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/permiso.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/dominio/sesion.dart';
import 'package:scei_qr/presentacion/acceso/menu_por_rol.dart';

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

  List<OpcionMenu> opciones() => [
        OpcionMenu(
          titulo: 'Escanear QR',
          permiso: Permiso.registrarUso,
          icono: Icons.qr_code_scanner,
          alSeleccionar: () {},
        ),
        OpcionMenu(
          titulo: 'Incidencias',
          permiso: Permiso.consultarIncidencias,
          icono: Icons.report_problem,
          alSeleccionar: () {},
        ),
        OpcionMenu(
          titulo: 'Equipos',
          permiso: Permiso.administrarEquipos,
          icono: Icons.computer,
          alSeleccionar: () {},
        ),
      ];

  List<String> titulosVisibles(Sesion? sesion) => opcionesPermitidas(
        opciones: opciones(),
        sesion: sesion,
        ahora: ahora,
      ).map((opcion) => opcion.titulo).toList();

  group('opcionesPermitidas', () {
    test('el alumno solo ve las opciones de su rol', () {
      expect(titulosVisibles(sesionDe(Rol.alumno)), ['Escanear QR']);
    });

    test('soporte ve incidencias pero no equipos', () {
      expect(titulosVisibles(sesionDe(Rol.soporteTecnico)), ['Incidencias']);
    });

    test('administrador ve las opciones de supervisión y gestión', () {
      expect(
        titulosVisibles(sesionDe(Rol.administrador)),
        ['Incidencias', 'Equipos'],
      );
    });

    test('sin sesión no hay opciones', () {
      expect(titulosVisibles(null), isEmpty);
    });

    test('con sesión vencida no hay opciones', () {
      final vencida = sesionDe(
        Rol.administrador,
        expiraEn: ahora.subtract(const Duration(minutes: 1)),
      );

      expect(titulosVisibles(vencida), isEmpty);
    });
  });

  group('MenuPorRol', () {
    testWidgets('muestra solo las opciones permitidas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuPorRol(
              sesion: sesionDe(Rol.soporteTecnico),
              opciones: opciones(),
              ahora: ahora,
            ),
          ),
        ),
      );

      expect(find.text('Incidencias'), findsOneWidget);
      expect(find.text('Escanear QR'), findsNothing);
      expect(find.text('Equipos'), findsNothing);
    });

    testWidgets('ejecuta la acción de la opción seleccionada', (tester) async {
      var seleccionada = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuPorRol(
              sesion: sesionDe(Rol.alumno),
              opciones: [
                OpcionMenu(
                  titulo: 'Escanear QR',
                  permiso: Permiso.registrarUso,
                  icono: Icons.qr_code_scanner,
                  alSeleccionar: () => seleccionada = 'escanear',
                ),
              ],
              ahora: ahora,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Escanear QR'));
      expect(seleccionada, 'escanear');
    });

    testWidgets('muestra el mensaje vacío cuando no hay opciones',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuPorRol(
              sesion: null,
              opciones: opciones(),
              ahora: ahora,
            ),
          ),
        ),
      );

      expect(
        find.text('No hay opciones disponibles para tu rol'),
        findsOneWidget,
      );
    });
  });
}

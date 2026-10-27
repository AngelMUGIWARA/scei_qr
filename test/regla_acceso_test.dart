// PRUEBAS DE ACCESO — HU-GEN-01 (Control de acceso por rol)
// Cubre la matriz rol × permiso y los criterios de aceptación 1, 2, 3 y 5
// en lo que corresponde al dominio de la app. Los criterios 4 (validación
// en el servidor) y las pruebas por endpoint son de la API.

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/permiso.dart';
import 'package:scei_qr/dominio/regla_acceso.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/dominio/sesion.dart';

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

  // Especificación esperada, escrita aparte de la regla a propósito:
  // si alguien cambia la matriz, estas pruebas deben avisar.
  const esperados = <Rol, Set<Permiso>>{
    Rol.alumno: {
      Permiso.registrarUso,
      Permiso.consultarMisRegistros,
      Permiso.reportarIncidencia,
      Permiso.consultarMisReportes,
    },
    Rol.soporteTecnico: {
      Permiso.atenderIncidencia,
      Permiso.escanearQrSitio,
      Permiso.consultarIncidencias,
      Permiso.consultarHistorialIncidencias,
    },
    Rol.administrador: {
      Permiso.consultarIncidencias,
      Permiso.consultarHistorialIncidencias,
      Permiso.administrarSoporte,
      Permiso.gestionarAlumnos,
      Permiso.administrarEquipos,
      Permiso.gestionarQr,
      Permiso.consultarHistorialUso,
      Permiso.consultarEstadisticas,
      Permiso.exportarReportes,
    },
  };

  group('Roles disponibles (criterio 1)', () {
    test('existen Alumno, Soporte técnico y Administrador', () {
      expect(
        Rol.values,
        containsAll([Rol.alumno, Rol.soporteTecnico, Rol.administrador]),
      );
      expect(Rol.values.length, 3);
    });

    test('todo permiso pertenece al menos a un rol', () {
      final asignados = esperados.values.expand((p) => p).toSet();
      expect(asignados, Permiso.values.toSet());
    });
  });

  group('Matriz rol × permiso', () {
    for (final rol in Rol.values) {
      for (final permiso in Permiso.values) {
        final permitido = esperados[rol]!.contains(permiso);
        test('${rol.name} ${permitido ? "SÍ" : "NO"} puede ${permiso.name}',
                () {
              final motivo = ReglaAcceso.validar(rol, permiso);
              if (permitido) {
                expect(motivo, isNull);
              } else {
                expect(motivo, 'No tienes permiso para esta acción');
              }
            });
      }
    }
  });

  group('Restricciones por criterio de aceptación', () {
    test('alumno no ejecuta funciones de soporte ni de administración '
        '(criterio 2)', () {
      final ajenos = {
        ...esperados[Rol.soporteTecnico]!,
        ...esperados[Rol.administrador]!,
      }.difference(esperados[Rol.alumno]!);

      for (final permiso in ajenos) {
        expect(ReglaAcceso.validar(Rol.alumno, permiso), isNotNull,
            reason: 'el alumno no debería tener ${permiso.name}');
      }
    });

    test('soporte solo gestiona incidencias, sin equipos ni personal '
        '(criterio 3)', () {
      const prohibidos = [
        Permiso.administrarEquipos,
        Permiso.gestionarQr,
        Permiso.administrarSoporte,
        Permiso.gestionarAlumnos,
      ];
      for (final permiso in prohibidos) {
        expect(ReglaAcceso.validar(Rol.soporteTecnico, permiso), isNotNull,
            reason: 'soporte no debería tener ${permiso.name}');
      }
      expect(
        ReglaAcceso.validar(Rol.soporteTecnico, Permiso.atenderIncidencia),
        isNull,
      );
    });

    test('administrador supervisa incidencias pero no las atiende (HU-AD-09)',
            () {
          expect(
            ReglaAcceso.validar(Rol.administrador, Permiso.consultarIncidencias),
            isNull,
          );
          expect(
            ReglaAcceso.validar(Rol.administrador, Permiso.atenderIncidencia),
            isNotNull,
          );
        });
  });

  group('Sin sesión y mensajes (criterio 5)', () {
    test('rol nulo devuelve un mensaje claro', () {
      expect(
        ReglaAcceso.validar(null, Permiso.registrarUso),
        'Inicia sesión para continuar',
      );
    });

    test('el rechazo no expone datos del usuario ni del permiso', () {
      final motivo =
      ReglaAcceso.validar(Rol.alumno, Permiso.administrarEquipos)!;
      expect(motivo.contains('administrarEquipos'), isFalse);
      expect(motivo.contains('alumno'), isFalse);
    });
  });

  group('validarSesion', () {
    test('sin sesión pide iniciar sesión', () {
      expect(
        ReglaAcceso.validarSesion(null, Permiso.registrarUso, ahora),
        'Inicia sesión para continuar',
      );
    });

    test('sesión vencida pide iniciar sesión de nuevo', () {
      final vencida =
      sesionDe(Rol.alumno, expiraEn: ahora.subtract(const Duration(minutes: 1)));
      expect(
        ReglaAcceso.validarSesion(vencida, Permiso.registrarUso, ahora),
        'Tu sesión expiró, inicia sesión de nuevo',
      );
    });

    test('sesión que vence justo ahora ya no es vigente', () {
      final limite = sesionDe(Rol.alumno, expiraEn: ahora);
      expect(limite.estaVigente(ahora), isFalse);
      expect(
        ReglaAcceso.validarSesion(limite, Permiso.registrarUso, ahora),
        isNotNull,
      );
    });

    test('sesión vigente con rol sin permiso es rechazada', () {
      expect(
        ReglaAcceso.validarSesion(
          sesionDe(Rol.alumno),
          Permiso.administrarEquipos,
          ahora,
        ),
        'No tienes permiso para esta acción',
      );
    });

    test('sesión vigente con rol correcto es permitida', () {
      expect(
        ReglaAcceso.validarSesion(
          sesionDe(Rol.administrador),
          Permiso.administrarEquipos,
          ahora,
        ),
        isNull,
      );
    });
  });
}
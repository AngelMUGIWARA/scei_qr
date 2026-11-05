// PRUEBAS DE LA DEFINICIÓN DEL ALTA — HU-AD-12
// Cubre el criterio "Se define cómo se dan de alta los alumnos" y la
// construcción del alumno a partir de la solicitud de alta.

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/alta_alumno.dart';
import 'package:scei_qr/dominio/rol.dart';

void main() {
  final fechaAlta = DateTime(2026, 10, 28, 9);

  SolicitudAltaAlumno solicitudValida() => const SolicitudAltaAlumno(
    nombre: 'Ana López',
    matricula: '20231234',
    correoInstitucional: 'Ana.Lopez@Universidad.edu.mx',
    contrasenaInicial: 'secreta123',
  );

  group('Mecanismo de alta definido por el equipo', () {
    test('el administrador da de alta por captura individual', () {
      expect(definicionAltaAlumno.mecanismo, MecanismoAlta.capturaIndividual);
      expect(definicionAltaAlumno.rolResponsable, Rol.administrador);
      expect(definicionAltaAlumno.permiteAutoregistro, isFalse);
      expect(definicionAltaAlumno.permiteCargaMasiva, isFalse);
    });

    test('usa la matrícula como identificador y el correo como credencial', () {
      expect(definicionAltaAlumno.identificador, 'matrícula');
      expect(definicionAltaAlumno.credencial, 'correo institucional');
      expect(definicionAltaAlumno.descripcion, contains('administrador'));
    });

    test(
      'la carga masiva y la integración escolar quedan fuera de alcance',
      () {
        expect(
          MecanismoAlta.values,
          containsAll([
            MecanismoAlta.capturaIndividual,
            MecanismoAlta.cargaMasiva,
            MecanismoAlta.integracionSistemaEscolar,
          ]),
        );
        expect(
          definicionAltaAlumno.mecanismo,
          isNot(MecanismoAlta.cargaMasiva),
        );
        expect(
          definicionAltaAlumno.mecanismo,
          isNot(MecanismoAlta.integracionSistemaEscolar),
        );
      },
    );
  });

  group('Solicitud de alta', () {
    test('normaliza matrícula, correo y usuario', () {
      final solicitud = solicitudValida();

      expect(solicitud.matriculaNormalizada, '20231234');
      expect(solicitud.correoNormalizado, 'ana.lopez@universidad.edu.mx');
      expect(solicitud.usuarioNormalizado, 'ana.lopez@universidad.edu.mx');
      expect(solicitud.esValida, isTrue);
      expect(solicitud.errores, isEmpty);
    });

    test('respeta el usuario cuando se indica uno distinto', () {
      const solicitud = SolicitudAltaAlumno(
        nombre: 'Ana López',
        matricula: '20231234',
        correoInstitucional: 'ana.lopez@universidad.edu.mx',
        contrasenaInicial: 'secreta123',
        usuario: 'Ana.Lopez',
      );

      expect(solicitud.usuarioNormalizado, 'ana.lopez');
    });

    test('crea un alumno activo con la fecha de alta recibida', () {
      final alumno = solicitudValida().aAlumno(fechaAlta: fechaAlta);

      expect(alumno.nombre, 'Ana López');
      expect(alumno.matricula, '20231234');
      expect(alumno.correoInstitucional, 'ana.lopez@universidad.edu.mx');
      expect(alumno.usuario, 'ana.lopez@universidad.edu.mx');
      expect(alumno.activo, isTrue);
      expect(alumno.fechaAlta, fechaAlta);
      expect(alumno.fechaBaja, isNull);
    });

    test('acumula todos los errores de una solicitud inválida', () {
      const solicitud = SolicitudAltaAlumno(
        nombre: 'Al',
        matricula: '123',
        correoInstitucional: 'sin-arroba',
        contrasenaInicial: 'corta',
      );

      expect(solicitud.esValida, isFalse);
      expect(solicitud.errores, hasLength(4));
      expect(
        solicitud.errores,
        containsAll([
          'El nombre debe tener al menos 3 caracteres',
          'La matrícula debe tener entre 6 y 12 caracteres',
          'El correo institucional no es válido',
          'La contraseña inicial debe tener al menos 8 caracteres',
        ]),
      );
      expect(
        () => solicitud.aAlumno(fechaAlta: fechaAlta),
        throwsArgumentError,
      );
    });
  });
}

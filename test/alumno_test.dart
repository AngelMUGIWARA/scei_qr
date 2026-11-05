// PRUEBAS DEL MODELO DE ALUMNO — HU-AD-12
// Cubre el criterio "Cada alumno tiene al menos nombre, matrícula y
// credenciales de acceso" y la baja lógica que conserva el historial.

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/alumno.dart';

void main() {
  final fechaAlta = DateTime(2026, 10, 28, 9);

  Alumno alumnoDePrueba() => Alumno(
    matricula: '20231234',
    nombre: 'Ana López',
    correoInstitucional: 'ana.lopez@universidad.edu.mx',
    usuario: 'ana.lopez@universidad.edu.mx',
    activo: true,
    fechaAlta: fechaAlta,
  );

  group('Datos mínimos del alumno', () {
    test('conserva nombre, matrícula, credencial y fecha de alta', () {
      final alumno = alumnoDePrueba();

      expect(alumno.nombre, 'Ana López');
      expect(alumno.matricula, '20231234');
      expect(alumno.correoInstitucional, 'ana.lopez@universidad.edu.mx');
      expect(alumno.usuario, 'ana.lopez@universidad.edu.mx');
      expect(alumno.fechaAlta, fechaAlta);
      expect(alumno.fechaBaja, isNull);
      expect(alumno.puedeIniciarSesion, isTrue);
      expect(alumno.estaDadoDeBaja, isFalse);
    });
  });

  group('Validación de datos de alta', () {
    test('acepta un nombre con al menos 3 caracteres', () {
      expect(Alumno.validarNombre('Ana'), isNull);
      expect(Alumno.validarNombre('  '), 'El nombre es obligatorio');
      expect(
        Alumno.validarNombre('Al'),
        'El nombre debe tener al menos 3 caracteres',
      );
    });

    test('acepta matrículas de 6 a 12 letras o números', () {
      expect(Alumno.validarMatricula('20231234'), isNull);
      expect(Alumno.validarMatricula('ABC123'), isNull);
      expect(Alumno.validarMatricula('  '), 'La matrícula es obligatoria');
      expect(
        Alumno.validarMatricula('123'),
        'La matrícula debe tener entre 6 y 12 caracteres',
      );
      expect(
        Alumno.validarMatricula('2023-1234'),
        'La matrícula solo admite letras y números',
      );
    });

    test('acepta solo correos con formato válido', () {
      expect(
        Alumno.validarCorreoInstitucional('ana@universidad.edu.mx'),
        isNull,
      );
      expect(
        Alumno.validarCorreoInstitucional(''),
        'El correo institucional es obligatorio',
      );
      expect(
        Alumno.validarCorreoInstitucional('ana.universidad'),
        'El correo institucional no es válido',
      );
    });

    test('acepta usuarios de 4 a 64 caracteres permitidos', () {
      expect(Alumno.validarUsuario('ana.lopez-2024_1'), isNull);
      expect(Alumno.validarUsuario('  '), 'El usuario es obligatorio');
      expect(
        Alumno.validarUsuario('ab'),
        'El usuario solo admite letras, números, arroba, punto, guion y '
        'guion bajo',
      );
    });

    test('exige una contraseña inicial de al menos 8 caracteres', () {
      expect(Alumno.validarContrasena('secreta123'), isNull);
      expect(
        Alumno.validarContrasena(''),
        'La contraseña inicial es obligatoria',
      );
      expect(
        Alumno.validarContrasena('corta'),
        'La contraseña inicial debe tener al menos 8 caracteres',
      );
    });
  });

  group('Baja lógica', () {
    test('deja de poder iniciar sesión pero conserva sus datos', () {
      final baja = alumnoDePrueba().darDeBaja(DateTime(2026, 11, 1));

      expect(baja.activo, isFalse);
      expect(baja.puedeIniciarSesion, isFalse);
      expect(baja.estaDadoDeBaja, isTrue);
      expect(baja.matricula, '20231234');
      expect(baja.nombre, 'Ana López');
      expect(baja.correoInstitucional, 'ana.lopez@universidad.edu.mx');
      expect(baja.fechaAlta, fechaAlta);
      expect(baja.fechaBaja, DateTime(2026, 11, 1));
    });

    test('reactivar vuelve a habilitar la cuenta sin fecha de baja', () {
      final reactivado = alumnoDePrueba()
          .darDeBaja(DateTime(2026, 11, 1))
          .reactivar();

      expect(reactivado.activo, isTrue);
      expect(reactivado.puedeIniciarSesion, isTrue);
      expect(reactivado.estaDadoDeBaja, isFalse);
      expect(reactivado.fechaBaja, isNull);
      expect(reactivado.fechaAlta, fechaAlta);
    });
  });
}

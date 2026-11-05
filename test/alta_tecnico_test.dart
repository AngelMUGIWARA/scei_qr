import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/alta_tecnico.dart';

void main() {
  SolicitudAltaTecnico solicitud({
    String nombreCompleto = 'Carlos Mena',
    String correo = 'carlos.mena@utez.edu.mx',
    String usuario = 'cmena',
    String contrasenaInicial = 'Password123!',
  }) {
    return SolicitudAltaTecnico(
      nombreCompleto: nombreCompleto,
      correo: correo,
      usuario: usuario,
      contrasenaInicial: contrasenaInicial,
    );
  }

  group('SolicitudAltaTecnico', () {
    test('acepta datos válidos', () {
      expect(solicitud().esValida, isTrue);
      expect(solicitud().errores, isEmpty);
    });

    test('normaliza nombre, correo y usuario', () {
      final datos = solicitud(
        nombreCompleto: '  Carlos Mena  ',
        correo: '  Carlos.Mena@UTEZ.EDU.MX  ',
        usuario: '  cmena  ',
      );

      expect(datos.nombreNormalizado, 'Carlos Mena');
      expect(datos.correoNormalizado, 'carlos.mena@utez.edu.mx');
      expect(datos.usuarioNormalizado, 'cmena');
    });

    test('exige un nombre de al menos 3 caracteres', () {
      expect(
        solicitud(nombreCompleto: '').errores,
        contains('El nombre completo es obligatorio'),
      );
      expect(
        solicitud(nombreCompleto: 'Al').errores,
        contains('El nombre debe tener al menos 3 caracteres'),
      );
    });

    test('exige un correo con formato válido', () {
      expect(
        solicitud(correo: '').errores,
        contains('El correo es obligatorio'),
      );
      expect(
        solicitud(correo: 'correo').errores,
        contains('El correo no es válido'),
      );
    });

    test('valida longitud y caracteres del usuario', () {
      expect(
        solicitud(usuario: 'ab').errores,
        contains('El usuario debe tener entre 4 y 64 caracteres'),
      );
      expect(
        solicitud(usuario: 'car los').errores,
        contains(
          'El usuario solo admite letras, números, arroba, punto, guion y '
          'guion bajo',
        ),
      );
    });

    test('exige una contraseña inicial de al menos 8 caracteres', () {
      expect(
        solicitud(contrasenaInicial: '').errores,
        contains('La contraseña inicial es obligatoria'),
      );
      expect(
        solicitud(contrasenaInicial: 'corta').errores,
        contains('La contraseña inicial debe tener al menos 8 caracteres'),
      );
    });

    test('acumula todos los errores de una solicitud inválida', () {
      final datos = solicitud(
        nombreCompleto: '',
        correo: 'sin-arroba',
        usuario: '',
        contrasenaInicial: '',
      );

      expect(datos.esValida, isFalse);
      expect(datos.errores, hasLength(4));
    });
  });
}

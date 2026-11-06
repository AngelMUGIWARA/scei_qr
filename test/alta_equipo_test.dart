import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';

void main() {
  SolicitudAltaEquipo solicitud({
    String identificador = 'LAB-PC-001',
    String laboratorio = 'Laboratorio de Cómputo 1',
    String ubicacion = 'Fila A, Mesa 3',
    String descripcion = 'Dell OptiPlex 3080',
  }) {
    return SolicitudAltaEquipo(
      identificador: identificador,
      laboratorio: laboratorio,
      ubicacion: ubicacion,
      descripcion: descripcion,
    );
  }

  group('SolicitudAltaEquipo', () {
    test('acepta datos válidos', () {
      expect(solicitud().esValida, isTrue);
      expect(solicitud().errores, isEmpty);
    });

    test('normaliza los cuatro campos', () {
      final datos = solicitud(
        identificador: '  LAB-PC-001  ',
        laboratorio: '  Laboratorio de Cómputo 1  ',
        ubicacion: '  Fila A  ',
        descripcion: '  Dell OptiPlex 3080  ',
      );

      expect(datos.identificadorNormalizado, 'LAB-PC-001');
      expect(datos.laboratorioNormalizado, 'Laboratorio de Cómputo 1');
      expect(datos.ubicacionNormalizada, 'Fila A');
      expect(datos.descripcionNormalizada, 'Dell OptiPlex 3080');
    });

    test('reporta el identificador obligatorio faltante', () {
      expect(
        solicitud(identificador: '   ').errores,
        contains('El identificador del equipo es obligatorio'),
      );
    });

    test('reporta el laboratorio obligatorio faltante', () {
      expect(
        solicitud(laboratorio: '').errores,
        contains('El laboratorio es obligatorio'),
      );
    });

    test('reporta la ubicación obligatoria faltante', () {
      expect(
        solicitud(ubicacion: '').errores,
        contains('La ubicación dentro del laboratorio es obligatoria'),
      );
    });

    test('la descripción es opcional', () {
      expect(solicitud(descripcion: '').esValida, isTrue);
    });

    test(
      'no valida formato/máscara del identificador (no definida en el HU)',
      () {
        // El HU solo exige unicidad (validada por el servidor); cualquier
        // valor no vacío es aceptado por el cliente.
        expect(solicitud(identificador: 'PC 01 /#').esValida, isTrue);
      },
    );

    test('acumula todos los errores de campos obligatorios', () {
      final errores = solicitud(
        identificador: '',
        laboratorio: '',
        ubicacion: '',
      ).errores;

      expect(errores, hasLength(3));
    });
  });
}

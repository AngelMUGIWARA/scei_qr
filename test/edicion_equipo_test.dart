import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';

void main() {
  group('SolicitudEdicionEquipo (HU-AD-05)', () {
    test('normaliza los campos y acepta una solicitud válida', () {
      const solicitud = SolicitudEdicionEquipo(
        codigo: '  LAB-PC-001  ',
        nombre: '  Equipo de laboratorio  ',
        descripcion: '  Dell OptiPlex  ',
        ubicacion: '  Fila A, Mesa 3  ',
      );

      expect(solicitud.codigoNormalizado, 'LAB-PC-001');
      expect(solicitud.nombreNormalizado, 'Equipo de laboratorio');
      expect(solicitud.descripcionNormalizada, 'Dell OptiPlex');
      expect(solicitud.ubicacionNormalizada, 'Fila A, Mesa 3');
      expect(solicitud.esValida, isTrue);
    });

    test('deriva el nombre del código cuando el nombre está vacío', () {
      const solicitud = SolicitudEdicionEquipo(
        codigo: 'LAB-PC-002',
        ubicacion: 'Fila B',
      );

      expect(solicitud.nombreEfectivo, 'LAB-PC-002');
    });

    test('conserva el nombre cuando el usuario lo proporciona', () {
      const solicitud = SolicitudEdicionEquipo(
        codigo: 'LAB-PC-002',
        nombre: 'Equipo de diseño',
        ubicacion: 'Fila B',
      );

      expect(solicitud.nombreEfectivo, 'Equipo de diseño');
    });

    test('exige identificador y ubicación', () {
      const solicitud = SolicitudEdicionEquipo(codigo: '  ', ubicacion: '');

      expect(solicitud.esValida, isFalse);
      expect(solicitud.errores, hasLength(2));
      expect(
        SolicitudEdicionEquipo.validarCodigo(''),
        'El identificador del equipo es obligatorio',
      );
      expect(
        SolicitudEdicionEquipo.validarUbicacion(' '),
        'La ubicación dentro del laboratorio es obligatoria',
      );
    });
  });
}

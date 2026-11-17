import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/usos/data/models/uso_model.dart';

void main() {
  final respuesta = <String, dynamic>{
    'id': 5,
    'alumnoId': 9,
    'equipoId': 12,
    'inicio': '2026-11-08T15:30:00.000Z',
    'fin': null,
    'estado': 'ACTIVO',
    'equipo': {
      'id': 12,
      'codigo': 'LAB-PC-001',
      'nombre': 'LAB-PC-001',
      'descripcion': 'Dell OptiPlex',
      'ubicacion': 'Fila A, Mesa 3',
      'qrToken': 'qr-token',
      'activo': true,
      'createdAt': '2026-11-05T12:00:00.000Z',
    },
  };

  group('UsoModel — HU-AL-03', () {
    test('mapea la respuesta de POST /usos al dominio', () {
      final uso = UsoModel.fromJson(respuesta).toEntity();

      expect(uso.id, 5);
      expect(uso.alumnoId, 9);
      expect(uso.equipoId, 12);
      expect(uso.inicio.toUtc(), DateTime.utc(2026, 11, 8, 15, 30));
      expect(uso.fin, isNull);
      expect(uso.estado, EstadoUso.activo);
      expect(uso.estaActivo, isTrue);
      expect(uso.equipo, isNotNull);
      expect(uso.equipo!.identificador, 'LAB-PC-001');
    });

    test('tolera equipo ausente y estado desconocido', () {
      final json = Map<String, dynamic>.from(respuesta)
        ..remove('equipo')
        ..['estado'] = 'OTRO';

      final uso = UsoModel.fromJson(json).toEntity();

      expect(uso.equipo, isNull);
      expect(uso.estado, EstadoUso.activo);
    });

    test('rechaza respuestas sin campos obligatorios', () {
      expect(() => UsoModel.fromJson(const {'id': 1}), throwsFormatException);
    });
  });
}

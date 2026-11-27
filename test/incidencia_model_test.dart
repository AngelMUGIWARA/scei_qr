import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/incidencia.dart';
import 'package:scei_qr/features/incidencias/data/models/incidencia_model.dart';

void main() {
  /// Respuesta real de `POST /incidencias`.
  Map<String, dynamic> json({
    int id = 42,
    String creadaEn = '2026-11-25T10:30:00.000Z',
    Object? folio,
    Object? tipo,
    Object? equipo,
  }) => {
    'id': id,
    'equipoId': 12,
    'reportadaPorId': 9,
    'atendidaPorId': null,
    'titulo': 'Hardware',
    'descripcion': 'La pantalla parpadea',
    'fotoUrl': null,
    'estado': 'PENDIENTE',
    'solucion': null,
    'creadaEn': creadaEn,
    'actualizadaEn': '2026-11-25T10:30:00.000Z',
    'equipo': equipo,
    'reportadaPor': {'id': 9, 'username': 'alumno1'},
    'atendidaPor': null,
    'folio': folio,
    'tipo': tipo,
  };

  group('IncidenciaModel — HU-AL-06 (folio)', () {
    test('deriva el folio INC-000042 con 6 dígitos', () {
      final model = IncidenciaModel.fromJson(
        json(id: 42),
        tipo: TipoProblema.hardware,
      );

      expect(model.folio, 'INC-000042');
      expect(model.id, 42);
    });

    test('con un id de 6 dígitos no agrega relleno', () {
      final model = IncidenciaModel.fromJson(
        json(id: 123456),
        tipo: TipoProblema.hardware,
      );

      expect(model.folio, 'INC-123456');
    });

    test('si el backend ya manda el folio se usa tal cual', () {
      final model = IncidenciaModel.fromJson(
        json(folio: 'INC-000099'),
        tipo: TipoProblema.hardware,
      );

      expect(model.folio, 'INC-000099');
    });

    test('la entidad de dominio conserva el folio', () {
      final entidad = IncidenciaModel.fromJson(
        json(id: 7),
        tipo: TipoProblema.red,
      ).toEntity();

      expect(entidad.folio, 'INC-000007');
    });
  });

  group('IncidenciaModel — HU-AL-06 (fecha de creación)', () {
    test('creadaEn en UTC se conserva como instante UTC', () {
      final model = IncidenciaModel.fromJson(
        json(creadaEn: '2026-11-25T10:30:00.000Z'),
        tipo: TipoProblema.hardware,
      );

      expect(model.fechaReporte.isUtc, isTrue);
      expect(model.fechaReporte, DateTime.utc(2026, 11, 25, 10, 30));
    });

    test('creadaEn con offset se convierte al mismo instante', () {
      final model = IncidenciaModel.fromJson(
        json(creadaEn: '2026-11-25T04:30:00-06:00'),
        tipo: TipoProblema.hardware,
      );

      expect(model.fechaReporte.toUtc(), DateTime.utc(2026, 11, 25, 10, 30));
    });

    test('creadaEn sin zona horaria se interpreta como hora local', () {
      final model = IncidenciaModel.fromJson(
        json(creadaEn: '2026-11-25T10:30:00'),
        tipo: TipoProblema.hardware,
      );

      expect(model.fechaReporte.isUtc, isFalse);
      expect(model.fechaReporte, DateTime(2026, 11, 25, 10, 30));
    });

    test('creadaEn inválido produce FormatException', () {
      expect(
        () => IncidenciaModel.fromJson(
          json(creadaEn: 'ayer'),
          tipo: TipoProblema.hardware,
        ),
        throwsFormatException,
      );
    });
  });

  group('IncidenciaModel — HU-AL-06 (resto del mapeo)', () {
    test('mapea los campos del serializador incident_public', () {
      final model = IncidenciaModel.fromJson(
        json(equipo: {'codigo': 'LAB-PC-001', 'ubicacion': 'Laboratorio 1'}),
        tipo: TipoProblema.software,
      );

      expect(model.equipoId, 12);
      expect(model.alumnoId, 9);
      expect(model.tipo, TipoProblema.software);
      expect(model.descripcion, 'La pantalla parpadea');
      expect(model.estado, EstadoIncidencia.pendiente);
      expect(model.equipoIdentificador, 'LAB-PC-001');
      expect(model.equipoUbicacion, 'Laboratorio 1');
    });

    test('el tipo viene del parámetro porque el API no lo expone', () {
      final model = IncidenciaModel.fromJson(
        json(),
        tipo: TipoProblema.perifericos,
      );

      expect(model.tipo, TipoProblema.perifericos);
    });

    test('si algún día el API expone "tipo" tiene prioridad', () {
      final model = IncidenciaModel.fromJson(
        json(tipo: 'RED'),
        tipo: TipoProblema.hardware,
      );

      expect(model.tipo, TipoProblema.red);
    });

    test('sin equipo embebido los campos opcionales quedan nulos', () {
      final model = IncidenciaModel.fromJson(
        json(equipo: null),
        tipo: TipoProblema.hardware,
      );

      expect(model.equipoIdentificador, isNull);
      expect(model.equipoUbicacion, isNull);
    });

    test('un campo obligatorio ausente produce FormatException', () {
      final roto = json()..remove('reportadaPorId');

      expect(
        () => IncidenciaModel.fromJson(roto, tipo: TipoProblema.hardware),
        throwsFormatException,
      );
    });
  });
}

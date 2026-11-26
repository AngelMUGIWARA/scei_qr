import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/uso.dart';

Uso _uso({DateTime? fin, EstadoUso estado = EstadoUso.activo}) => Uso(
  id: 5,
  alumnoId: 9,
  equipoId: 12,
  inicio: DateTime.utc(2026, 11, 8, 15, 30),
  fin: fin,
  estado: estado,
);

void main() {
  group('Uso — HU-AL-04 (duración)', () {
    test('la duración es fin - inicio con las fechas del servidor', () {
      final uso = _uso(
        fin: DateTime.utc(2026, 11, 8, 17, 5, 30),
        estado: EstadoUso.finalizado,
      );

      expect(uso.duracion, const Duration(hours: 1, minutes: 35, seconds: 30));
    });

    test('mientras el uso está activo no hay duración', () {
      expect(_uso().duracion, isNull);
    });

    test('no depende de la zona horaria en que se expresen las fechas', () {
      final inicioLocal = DateTime.utc(2026, 11, 8, 15, 30).toLocal();
      final uso = Uso(
        id: 5,
        alumnoId: 9,
        equipoId: 12,
        inicio: inicioLocal,
        fin: DateTime.utc(2026, 11, 8, 16, 0),
        estado: EstadoUso.finalizado,
      );

      expect(uso.duracion, const Duration(minutes: 30));
    });
  });

  group('Uso — HU-AL-04 (uso activo)', () {
    test('estado ACTIVO es un uso activo', () {
      expect(EstadoUso.desdeApi('ACTIVO'), EstadoUso.activo);
      expect(_uso().estaActivo, isTrue);
    });

    test('estado FINALIZADO no es un uso activo', () {
      expect(EstadoUso.desdeApi('FINALIZADO'), EstadoUso.finalizado);
      expect(
        _uso(
          fin: DateTime.utc(2026, 11, 8, 16),
          estado: EstadoUso.finalizado,
        ).estaActivo,
        isFalse,
      );
    });
  });
}

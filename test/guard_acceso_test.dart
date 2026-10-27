import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/permiso.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/dominio/sesion.dart';
import 'package:scei_qr/presentacion/acceso/guard_acceso.dart';

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

  GuardAcceso guardCon(Sesion? sesion) =>
      GuardAcceso(sesion: () => sesion, ahora: () => ahora);

  group('GuardAcceso', () {
    test('permite un permiso del rol con sesión vigente', () {
      final guard = guardCon(sesionDe(Rol.alumno));

      expect(guard.motivoPara(Permiso.registrarUso), isNull);
      expect(guard.permite(Permiso.registrarUso), isTrue);
    });

    test('rechaza sin sesión con el mensaje del dominio', () {
      final guard = guardCon(null);

      expect(
        guard.motivoPara(Permiso.registrarUso),
        'Inicia sesión para continuar',
      );
      expect(guard.permite(Permiso.registrarUso), isFalse);
    });

    test('rechaza una sesión vencida con el mensaje del dominio', () {
      final guard = guardCon(
        sesionDe(
          Rol.alumno,
          expiraEn: ahora.subtract(const Duration(minutes: 1)),
        ),
      );

      expect(
        guard.motivoPara(Permiso.registrarUso),
        'Tu sesión expiró, inicia sesión de nuevo',
      );
    });

    test('rechaza un permiso ajeno al rol', () {
      final guard = guardCon(sesionDe(Rol.alumno));

      expect(
        guard.motivoPara(Permiso.administrarEquipos),
        'No tienes permiso para esta acción',
      );
    });

    test('consulta la sesión en cada validación', () {
      Sesion? sesion;
      final guard = GuardAcceso(sesion: () => sesion, ahora: () => ahora);

      expect(guard.permite(Permiso.registrarUso), isFalse);
      sesion = sesionDe(Rol.alumno);
      expect(guard.permite(Permiso.registrarUso), isTrue);
    });

    test('exigir no lanza cuando el acceso está permitido', () {
      final guard = guardCon(sesionDe(Rol.administrador));

      expect(() => guard.exigir(Permiso.administrarEquipos), returnsNormally);
    });

    test('exigir lanza AccesoDenegado con el motivo del dominio', () {
      final guard = guardCon(sesionDe(Rol.alumno));

      expect(
        () => guard.exigir(Permiso.administrarEquipos),
        throwsA(
          isA<AccesoDenegado>().having(
            (error) => error.motivo,
            'motivo',
            'No tienes permiso para esta acción',
          ),
        ),
      );
    });
  });
}

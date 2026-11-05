import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/features/auth/data/repositories/auth_repository_impl.dart';

import 'fakes_auth.dart';

void main() {
  group('AuthRepositoryImpl.login', () {
    test('éxito: guarda token y usuario en el almacenamiento seguro', () async {
      final remote = FakeRemoteDataSource(respuesta: respuestaLogin());
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(remote: remote, storage: storage);

      final sesion = await repo.login('alumno1', 'Password123!');

      expect(sesion.rol, Rol.alumno);
      expect(sesion.nombreCompleto, 'Lucía Fernández');
      expect(remote.llamadas, 1);
      expect(storage.token, isNotNull);
      expect(storage.sessionJson, isNotNull);
      expect(storage.userJson, isNotNull);
      expect(jsonDecode(storage.userJson!)['username'], 'alumno1');
      expect(storage.saveCount, 1);
    });

    test('traduce los 3 roles del backend al enum de dominio', () async {
      final storage = FakeStorage();

      for (final (api, esperado) in [
        ('ALUMNO', Rol.alumno),
        ('SOPORTE', Rol.soporteTecnico),
        ('ADMIN', Rol.administrador),
      ]) {
        final remote = FakeRemoteDataSource(
          respuesta: respuestaLogin(rol: api),
        );
        final sesion = await AuthRepositoryImpl(
          remote: remote,
          storage: storage,
        ).login('alumno1', 'Password123!');
        expect(sesion.rol, esperado, reason: 'rol API $api');
      }
    });

    test(
      '401 del backend lanza AuthException genérico y no guarda nada',
      () async {
        final remote = FakeRemoteDataSource(error: const AuthException());
        final storage = FakeStorage();
        final repo = AuthRepositoryImpl(remote: remote, storage: storage);

        await expectLater(
          repo.login('alumno1', 'mala'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'mensaje',
              'Usuario o contraseña incorrectos',
            ),
          ),
        );
        expect(storage.token, isNull);
      },
    );

    test('permite el acceso cuando la cuenta es Administrador', () async {
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin(rol: 'ADMIN')),
        storage: storage,
      );

      final sesion = await repo.login('admin', 'Password123!');

      expect(sesion.rol, Rol.administrador);
      expect(storage.token, isNotNull);
      expect(storage.sessionJson, isNotNull);
    });

    test('rechaza un token malformado y no lo persiste', () async {
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(
          respuesta: respuestaLogin(accessToken: 'token-invalido'),
        ),
        storage: storage,
      );

      await expectLater(
        repo.login('alumno1', 'Password123!'),
        throwsA(isA<ServerException>()),
      );

      expect(storage.saveCount, 0);
      expect(storage.sessionJson, isNull);
    });

    test('rechaza un token vacío y no lo persiste', () async {
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(
          respuesta: respuestaLogin(accessToken: ''),
        ),
        storage: storage,
      );

      await expectLater(
        repo.login('alumno1', 'Password123!'),
        throwsA(isA<ServerException>()),
      );

      expect(storage.saveCount, 0);
      expect(storage.sessionJson, isNull);
    });

    test('no acepta expiresIn como sustituto de un JWT válido', () async {
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(
          respuesta: respuestaLogin(
            accessToken: 'token-invalido',
            expiresIn: 28800,
          ),
        ),
        storage: storage,
      );

      await expectLater(
        repo.login('alumno1', 'Password123!'),
        throwsA(isA<ServerException>()),
      );

      expect(storage.saveCount, 0);
      expect(storage.sessionJson, isNull);
    });

    test(
      'rol desconocido del backend se trata como error de servidor',
      () async {
        final remote = FakeRemoteDataSource(
          respuesta: respuestaLogin(rol: 'SUPERVISOR'),
        );
        final repo = AuthRepositoryImpl(remote: remote, storage: FakeStorage());

        expect(
          () => repo.login('alumno1', 'Password123!'),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('AuthRepositoryImpl.restoreSession', () {
    test('sin datos persistidos devuelve null', () async {
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
        storage: FakeStorage(),
      );

      expect(await repo.restoreSession(), isNull);
    });

    test(
      'token vigente restaura la sesión con la expiración del JWT',
      () async {
        final expira = DateTime.now().add(const Duration(hours: 8));
        final token = jwtDePrueba(expira: expira);
        final userJson = jsonEncode({
          'usuarioId': 1,
          'username': 'alumno1',
          'nombreCompleto': 'Lucía Fernández',
          'rol': 'alumno',
          'expiraEn': expira.toIso8601String(),
        });

        final storage = FakeStorage()
          ..sessionJson = jsonEncode({'token': token, 'user': userJson});
        final repo = AuthRepositoryImpl(
          remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
          storage: storage,
        );

        final sesion = await repo.restoreSession();

        expect(sesion, isNotNull);
        expect(sesion!.rol, Rol.alumno);
        expect(sesion.username, 'alumno1');
        expect(sesion.token, token);
        expect(
          sesion.expiraEn.difference(expira).inSeconds.abs(),
          lessThan(2),
          reason: 'expiraEn debe salir del claim exp del JWT',
        );
        expect(sesion.estaVigente(DateTime.now()), isTrue);
      },
    );

    test('token expirado limpia el almacenamiento y devuelve null', () async {
      final storage = FakeStorage()
        ..token = jwtDePrueba(
          expira: DateTime.now().subtract(const Duration(hours: 1)),
        )
        ..userJson = jsonEncode({
          'usuarioId': 1,
          'username': 'alumno1',
          'nombreCompleto': 'Lucía Fernández',
          'rol': 'alumno',
        });
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
        storage: storage,
      );

      expect(await repo.restoreSession(), isNull);
      expect(storage.fueLimpiado, isTrue);
      expect(storage.sessionJson, isNull);
      expect(storage.token, isNull);
      expect(storage.userJson, isNull);
    });

    test('token no decodificable limpia el almacenamiento', () async {
      final storage = FakeStorage()
        ..token = 'esto-no-es-un-jwt'
        ..userJson = jsonEncode({
          'usuarioId': 1,
          'username': 'alumno1',
          'nombreCompleto': 'Lucía Fernández',
          'rol': 'alumno',
        });
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
        storage: storage,
      );

      expect(await repo.restoreSession(), isNull);
      expect(storage.fueLimpiado, isTrue);
    });

    test('registro corrupto limpia el almacenamiento', () async {
      final storage = FakeStorage()
        ..token = jwtDePrueba(
          expira: DateTime.now().add(const Duration(hours: 1)),
        )
        ..userJson = '{esto no es json';
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
        storage: storage,
      );

      expect(await repo.restoreSession(), isNull);
      expect(storage.fueLimpiado, isTrue);
    });

    test('una sesión persistida de cualquier rol se restaura', () async {
      final storage = FakeStorage()
        ..token = jwtDePrueba(
          expira: DateTime.now().add(const Duration(hours: 1)),
        )
        ..userJson = jsonEncode({
          'usuarioId': 1,
          'username': 'alumno1',
          'nombreCompleto': 'Lucía Fernández',
          'rol': 'alumno',
        });
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
        storage: storage,
      );

      final sesion = await repo.restoreSession();

      expect(sesion, isNotNull);
      expect(sesion!.rol, Rol.alumno);
      expect(storage.fueLimpiado, isFalse);
    });
  });

  group('AuthRepositoryImpl.cerrarSesion (HU-GEN-02)', () {
    test('elimina el token y la sesión persistida', () async {
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
        storage: storage,
      );

      await repo.login('alumno1', 'Password123!');
      expect(storage.sessionJson, isNotNull);

      await repo.cerrarSesion();

      expect(storage.fueLimpiado, isTrue);
      expect(storage.sessionJson, isNull);
      expect(storage.token, isNull);
      expect(storage.userJson, isNull);
    });

    test('sin datos persistidos no falla', () async {
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin()),
        storage: FakeStorage(),
      );

      await expectLater(repo.cerrarSesion(), completes);
    });
  });
}

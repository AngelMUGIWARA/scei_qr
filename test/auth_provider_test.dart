import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/features/auth/domain/usecases/cerrar_sesion_usecase.dart';
import 'package:scei_qr/features/auth/domain/usecases/login_usecase.dart';
import 'package:scei_qr/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:scei_qr/features/auth/presentation/providers/auth_provider.dart';

import 'fakes_auth.dart';

void main() {
  AuthProvider crearProvider(FakeAuthRepository repo) => AuthProvider(
    loginUseCase: LoginUseCase(repo),
    restoreSessionUseCase: RestoreSessionUseCase(repo),
    cerrarSesionUseCase: CerrarSesionUseCase(repo),
  );

  group('AuthProvider.login', () {
    test('éxito: pasa de loading a authenticated con la sesión', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(rol: Rol.administrador),
      );
      final provider = crearProvider(repo);
      final estados = <AuthStatus>[];
      provider.addListener(() => estados.add(provider.status));

      final ok = await provider.login('admin', 'Password123!');

      expect(ok, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.session!.rol, Rol.administrador);
      expect(provider.errorMessage, isNull);
      expect(estados, [AuthStatus.loading, AuthStatus.authenticated]);
    });

    test('credenciales inválidas: estado error con mensaje genérico', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => throw const AuthException(),
      );
      final provider = crearProvider(repo);

      final ok = await provider.login('alumno1', 'Password123!');

      expect(ok, isFalse);
      expect(provider.status, AuthStatus.error);
      expect(provider.errorMessage, 'Usuario o contraseña incorrectos');
      expect(provider.session, isNull);
      expect(provider.isAuthenticated, isFalse);
    });

    test('cuenta inactiva usa el mismo mensaje genérico (HU-ST-01)', () async {
      // El backend devuelve el mismo 401 para cuenta desactivada.
      final repo = FakeAuthRepository(
        alLogin: (_, _) async =>
            throw const AuthException('Usuario o contraseña incorrectos'),
      );
      final provider = crearProvider(repo);

      await provider.login('soporte', 'Password123!');

      expect(provider.errorMessage, 'Usuario o contraseña incorrectos');
    });

    test('error inesperado no filtra detalles internos', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => throw Exception('clave de la BD: xxx'),
      );
      final provider = crearProvider(repo);

      await provider.login('alumno1', 'Password123!');

      expect(provider.status, AuthStatus.error);
      expect(provider.errorMessage, 'Usuario o contraseña incorrectos');
      expect(provider.errorMessage, isNot(contains('BD')));
    });

    test('clearError elimina el mensaje sin cambiar el estado', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => throw const AuthException(),
      );
      final provider = crearProvider(repo);

      await provider.login('alumno1', 'Password123!');
      provider.clearError();

      expect(provider.errorMessage, isNull);
      expect(provider.status, AuthStatus.error);
    });
  });

  group('AuthProvider.restoreSession', () {
    test('con sesión persistida queda autenticado', () async {
      final repo = FakeAuthRepository(
        alRestaurar: () async => sesionDePrueba(),
      );
      final provider = crearProvider(repo);

      await provider.restoreSession();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.session, isNotNull);
      expect(repo.restoreLlamadas, 1);
    });

    test('sin sesión persistida queda unauthenticated', () async {
      final provider = crearProvider(FakeAuthRepository());

      await provider.restoreSession();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.session, isNull);
    });
  });

  group('AuthProvider.cerrarSesion (HU-GEN-02)', () {
    test('cierra la sesión, borra el token y queda unauthenticated', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(rol: Rol.soporteTecnico),
      );
      final provider = crearProvider(repo);
      await provider.login('soporte', 'Password123!');
      expect(provider.isAuthenticated, isTrue);

      await provider.cerrarSesion();

      expect(repo.cerrarSesionLlamadas, 1);
      expect(provider.session, isNull);
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.errorMessage, isNull);
    });

    test('si el almacenamiento falla igual cierra la sesión en memoria',
        () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(),
        falloAlCerrar: true,
      );
      final provider = crearProvider(repo);
      await provider.login('alumno1', 'Password123!');

      await provider.cerrarSesion();

      expect(repo.cerrarSesionLlamadas, 1);
      expect(provider.session, isNull);
      expect(provider.status, AuthStatus.unauthenticated);
    });

    test('no deja mensaje de error de un intento anterior', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => throw const AuthException(),
      );
      final provider = crearProvider(repo);
      await provider.login('alumno1', 'mal');
      expect(provider.errorMessage, isNotNull);

      await provider.cerrarSesion();

      expect(provider.errorMessage, isNull);
    });
  });
}

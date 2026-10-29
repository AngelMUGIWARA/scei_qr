import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/features/auth/domain/usecases/login_usecase.dart';

import 'fakes_auth.dart';

void main() {
  group('LoginUseCase', () {
    test('credenciales válidas devuelve la sesión del repositorio', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(rol: Rol.soporteTecnico),
      );
      final useCase = LoginUseCase(repo);

      final sesion = await useCase('soporte01', 'Password123!');

      expect(sesion.rol, Rol.soporteTecnico);
      expect(repo.loginLlamadas, 1);
      expect(repo.ultimoUsername, 'soporte01');
      expect(repo.ultimoPassword, 'Password123!');
    });

    test('recorta el usuario antes de enviarlo', () async {
      final repo = FakeAuthRepository(alLogin: (_, _) async => sesionDePrueba());

      await LoginUseCase(repo)('  alumno1  ', 'Password123!');

      expect(repo.ultimoUsername, 'alumno1');
    });

    test('usuario vacío lanza ValidationException sin llamar al backend', () async {
      final repo = FakeAuthRepository(alLogin: (_, _) async => sesionDePrueba());

      expect(
        () => LoginUseCase(repo)('   ', 'Password123!'),
        throwsA(isA<ValidationException>()),
      );
      expect(repo.loginLlamadas, 0);
    });

    test('contraseña vacía lanza ValidationException sin llamar al backend', () async {
      final repo = FakeAuthRepository(alLogin: (_, _) async => sesionDePrueba());

      expect(
        () => LoginUseCase(repo)('alumno1', ''),
        throwsA(isA<ValidationException>()),
      );
      expect(repo.loginLlamadas, 0);
    });

    test('contraseña corta usa el mensaje genérico (no revela el campo)', () async {
      final repo = FakeAuthRepository(alLogin: (_, _) async => sesionDePrueba());

      expect(
        () => LoginUseCase(repo)('alumno1', '123'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.message, 'mensaje', 'Usuario o contraseña incorrectos'),
        ),
      );
      expect(repo.loginLlamadas, 0);
    });

    test('propaga el error del repositorio', () async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => throw const AuthException(),
      );

      expect(
        () => LoginUseCase(repo)('alumno1', 'Password123!'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:scei_qr/features/auth/domain/repositories/auth_repository.dart';
import 'package:scei_qr/features/auth/domain/usecases/login_usecase.dart';
import 'package:scei_qr/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:scei_qr/features/auth/presentation/providers/auth_provider.dart';
import 'package:scei_qr/features/auth/presentation/screens/home_screen.dart';
import 'package:scei_qr/features/auth/presentation/screens/login_screen.dart';

import 'fakes_auth.dart';

void main() {
  AuthProvider providerDe(AuthRepository repo) => AuthProvider(
    loginUseCase: LoginUseCase(repo),
    restoreSessionUseCase: RestoreSessionUseCase(repo),
  );

  Future<void> pumpLogin(WidgetTester tester, AuthRepository repo) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: providerDe(repo),
        child: MaterialApp(
          home: const LoginScreen(),
          routes: {'/home/admin': (_) => const HomeScreen()},
        ),
      ),
    );
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();
  }

  Future<void> ingresar(
    WidgetTester tester, {
    String username = 'admin',
    String password = 'Password123!',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), username);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await enviar(tester);
  }

  group('LoginScreen — HU-AD-01', () {
    testWidgets('muestra el formulario de usuario y contraseña', (
      tester,
    ) async {
      await pumpLogin(tester, FakeAuthRepository());

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('valida campos vacíos antes de enviar', (tester) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(rol: Rol.administrador),
      );
      await pumpLogin(tester, repo);

      await enviar(tester);

      expect(find.text('Ingresa tu usuario'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      expect(repo.loginLlamadas, 0, reason: 'no debe llamar al backend');
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('credenciales inválidas muestran el mensaje genérico', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => throw const AuthException(),
      );
      await pumpLogin(tester, repo);

      await ingresar(tester, username: 'admin', password: 'incorrecta');

      expect(find.byKey(const Key('login_error_message')), findsOneWidget);
      expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('una cuenta sin rol Administrador es rechazada', (
      tester,
    ) async {
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin(rol: 'ALUMNO')),
        storage: storage,
        rolRequerido: Rol.administrador,
      );
      await pumpLogin(tester, repo);

      await ingresar(tester, username: 'alumno1');

      expect(
        find.text('Esta cuenta no tiene permisos de administrador'),
        findsOneWidget,
      );
      expect(find.byType(HomeScreen), findsNothing);
      expect(storage.token, isNull, reason: 'no debe persistir la sesión');
    });

    testWidgets('un administrador entra al panel con su menú de gestión', (
      tester,
    ) async {
      final storage = FakeStorage();
      final repo = AuthRepositoryImpl(
        remote: FakeRemoteDataSource(respuesta: respuestaLogin(rol: 'ADMIN')),
        storage: storage,
        rolRequerido: Rol.administrador,
      );
      await pumpLogin(tester, repo);

      await ingresar(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Menú de gestión'), findsOneWidget);
      expect(find.text('Gestionar alumnos'), findsOneWidget);
      expect(find.text('Administrar equipos'), findsOneWidget);
      expect(find.text('Gestionar códigos QR'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsNothing);
      expect(storage.token, isNotNull);
    });

    testWidgets('el campo de contraseña se puede ocultar/mostrar', (
      tester,
    ) async {
      await pumpLogin(tester, FakeAuthRepository());

      final campo = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(campo.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      final visible = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(visible.obscureText, isFalse);
    });
  });
}

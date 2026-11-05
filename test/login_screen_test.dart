
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/features/auth/domain/repositories/auth_repository.dart';
import 'package:scei_qr/features/auth/domain/usecases/cerrar_sesion_usecase.dart';
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
    cerrarSesionUseCase: CerrarSesionUseCase(repo),
  );

  Future<void> pumpLogin(WidgetTester tester, AuthRepository repo) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: providerDe(repo),
        child: MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/home': (_) => const HomeScreen(),
          },
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

  group('LoginScreen — inicio de sesión y control de acceso', () {
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
      expect(repo.loginLlamadas, 0);
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

    testWidgets(
      'una contraseña corta muestra el error genérico sin revelar detalles',
          (tester) async {
        final repo = FakeAuthRepository();

        await pumpLogin(tester, repo);
        await ingresar(
          tester,
          username: 'admin',
          password: '123',
        );

        expect(repo.loginLlamadas, 0);
        expect(find.text('Mínimo 6 caracteres'), findsNothing);
        expect(
          find.text('Usuario o contraseña incorrectos'),
          findsOneWidget,
        );
      },
    );

    testWidgets('un alumno accede a su pantalla correspondiente', (
        tester,
        ) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(rol: Rol.alumno),
      );

      await pumpLogin(tester, repo);
      await ingresar(tester, username: 'alumno1');

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Escanear código QR'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsNothing);
    });

    testWidgets('soporte técnico accede a su pantalla correspondiente', (
        tester,
        ) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(
          rol: Rol.soporteTecnico,
          username: 'soporte',
          nombreCompleto: 'Carlos Mena',
        ),
      );

      await pumpLogin(tester, repo);
      await ingresar(tester, username: 'soporte');

      expect(find.text('Incidencias reportadas'), findsOneWidget);
    });

    testWidgets('un administrador accede a su pantalla correspondiente', (
        tester,
        ) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(
          rol: Rol.administrador,
          username: 'admin',
          nombreCompleto: 'Ana Torres',
        ),
      );

      await pumpLogin(tester, repo);
      await ingresar(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Administrar equipos'), findsOneWidget);
      expect(find.text('Escanear código QR'), findsNothing);
      expect(find.text('Iniciar sesión'), findsNothing);
    });

    testWidgets('el campo de contraseña se puede ocultar y mostrar', (
        tester,
        ) async {
      await pumpLogin(tester, FakeAuthRepository());

      final campo = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );

      expect(campo.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      final visible = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );

      expect(visible.obscureText, isFalse);
    });
  });

  group('HU-GEN-02 — cerrar sesión en los 3 roles', () {
    for (final (etiqueta, rol, username, textoHome) in [
      ('alumno', Rol.alumno, 'alumno1', 'Escanear código QR'),
      ('soporte técnico', Rol.soporteTecnico, 'soporte', 'Incidencias reportadas'),
      ('administrador', Rol.administrador, 'admin', 'Administrar equipos'),
    ]) {
      testWidgets('un $etiqueta cierra sesión y vuelve al login', (
        tester,
      ) async {
        final repo = FakeAuthRepository(
          alLogin: (_, _) async => sesionDePrueba(rol: rol, username: username),
        );

        await pumpLogin(tester, repo);
        await ingresar(tester, username: username);

        // Estamos en el home del rol con la opción de cerrar sesión visible.
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text(textoHome), findsOneWidget);
        expect(find.byKey(const Key('logout_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle();

        // CA: se borró la sesión y se volvió al login.
        expect(repo.cerrarSesionLlamadas, 1);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byKey(const Key('login_button')), findsOneWidget);

        // CA: no se puede volver a las pantallas internas con el botón "atrás".
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator),
        );
        expect(navigator.canPop(), isFalse);
      });
    }
  });
}

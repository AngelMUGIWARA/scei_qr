import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/rol.dart';
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
          routes: {
            '/home': (_) => const HomeScreen(),
            '/home/alumno': (_) => const HomeScreen(),
            '/home/soporte': (_) => const HomeScreen(),
            '/home/admin': (_) => const HomeScreen(),
          },
        ),
      ),
    );
  }

  Future<void> enviar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();
  }

  group('LoginScreen — HU-AL-01', () {
    testWidgets('muestra el formulario de usuario y contraseña', (tester) async {
      await pumpLogin(tester, FakeAuthRepository());

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('valida campos vacíos antes de enviar', (tester) async {
      final repo = FakeAuthRepository(alLogin: (_, _) async => sesionDePrueba());
      await pumpLogin(tester, repo);

      await enviar(tester);

      expect(find.text('Ingresa tu usuario'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      expect(repo.loginLlamadas, 0, reason: 'no debe llamar al backend');
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('credenciales inválidas muestran el mensaje genérico',
        (tester) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => throw const AuthException(),
      );
      await pumpLogin(tester, repo);

      await tester.enterText(find.byType(TextFormField).at(0), 'alumno1');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await enviar(tester);

      expect(
        find.byKey(const Key('login_error_message')),
        findsOneWidget,
      );
      expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('credenciales válidas navega al home del Alumno (HU-AL-01)',
        (tester) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(rol: Rol.alumno),
      );
      await pumpLogin(tester, repo);

      await tester.enterText(find.byType(TextFormField).at(0), 'alumno1');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await enviar(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Escanear código QR'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsNothing);
    });

    testWidgets('rol Soporte técnico entra a su pantalla (HU-ST-01)',
        (tester) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(
          rol: Rol.soporteTecnico,
          username: 'soporte',
          nombreCompleto: 'Carlos Mena',
        ),
      );
      await pumpLogin(tester, repo);

      await tester.enterText(find.byType(TextFormField).at(0), 'soporte');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await enviar(tester);

      expect(find.text('Incidencias reportadas'), findsOneWidget);
    });

    testWidgets('rol Administrador entra a su pantalla (HU-AD-01)',
        (tester) async {
      final repo = FakeAuthRepository(
        alLogin: (_, _) async => sesionDePrueba(
          rol: Rol.administrador,
          username: 'admin',
          nombreCompleto: 'Ana Torres',
        ),
      );
      await pumpLogin(tester, repo);

      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await enviar(tester);

      expect(find.text('Registrar equipos de cómputo'), findsOneWidget);
      expect(find.text('Escanear código QR'), findsNothing,
          reason: 'un admin no ve funciones de alumno (HU-GEN-01)');
    });

    testWidgets('el campo de contraseña se puede ocultar/mostrar',
        (tester) async {
      await pumpLogin(tester, FakeAuthRepository());

      final campo = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(campo.obscureText, isTrue);

      // Con la contraseña oculta se muestra el icono "visibility_off".
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      final visible = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(visible.obscureText, isFalse);
    });
  });
}

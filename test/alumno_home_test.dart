import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/dominio/uso.dart';
import 'package:scei_qr/features/auth/domain/usecases/cerrar_sesion_usecase.dart';
import 'package:scei_qr/features/auth/domain/usecases/login_usecase.dart';
import 'package:scei_qr/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:scei_qr/features/auth/presentation/providers/auth_provider.dart';
import 'package:scei_qr/features/auth/presentation/screens/homes/alumno_home.dart';
import 'package:scei_qr/features/usos/domain/repositories/usos_repository.dart';

import 'fakes_auth.dart';

class _SinUsoActivoRepository implements UsosRepository {
  @override
  Future<Uso?> obtenerUsoActivo() async => null;

  @override
  Future<Uso> finalizarUso(int usoId) async => throw UnimplementedError();

  @override
  Future<Uso> iniciarUso(String qrToken) async => throw UnimplementedError();
}

Future<AuthProvider> _providerDeRol(Rol rol) async {
  final repo = FakeAuthRepository(
    alLogin: (_, _) async => sesionDePrueba(rol: rol),
  );
  final provider = AuthProvider(
    loginUseCase: LoginUseCase(repo),
    restoreSessionUseCase: RestoreSessionUseCase(repo),
    cerrarSesionUseCase: CerrarSesionUseCase(repo),
  );
  await provider.login('alumno1', 'Password123!');
  return provider;
}

Future<void> _pantalla(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<UsosRepository>.value(value: _SinUsoActivoRepository()),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: const MaterialApp(home: AlumnoHome()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const opcionReportar = Key('alumno_reportar_incidencia');

  group('AlumnoHome — HU-AL-06 (opción con Permiso.reportarIncidencia)', () {
    testWidgets('el alumno ve la opción "Reportar incidencia"', (tester) async {
      await _pantalla(tester, await _providerDeRol(Rol.alumno));

      final opcion = find.byKey(opcionReportar);
      expect(opcion, findsOneWidget);
      expect(find.text('Reportar incidencia'), findsOneWidget);
      expect(
        tester.widget<ListTile>(opcion).title,
        isA<Text>().having((t) => t.data, 'texto', 'Reportar incidencia'),
      );
    });

    testWidgets('un rol sin el permiso no la ve', (tester) async {
      await _pantalla(tester, await _providerDeRol(Rol.soporteTecnico));

      expect(find.byKey(opcionReportar), findsNothing);
      expect(find.text('Reportar incidencia'), findsNothing);

      // El resto del menú sigue visible.
      expect(find.byKey(const Key('alumno_escanear_qr')), findsOneWidget);
    });

    testWidgets('un administrador tampoco la ve', (tester) async {
      await _pantalla(tester, await _providerDeRol(Rol.administrador));

      expect(find.byKey(opcionReportar), findsNothing);
      expect(find.text('Reportar incidencia'), findsNothing);
    });
  });
}

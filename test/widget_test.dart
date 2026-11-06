// Smoke test de la app con sesión restaurada por un repositorio falso.
// (La demo del contador fue reemplazada por el login real.)

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/alta_tecnico.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/dominio/tecnico.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/usuarios/domain/repositories/usuarios_repository.dart';
import 'package:scei_qr/main.dart';

import 'fakes_auth.dart';

class _FakeEquiposRepository implements EquiposRepository {
  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    return Equipo(
      id: 1,
      identificador: solicitud.identificadorNormalizado,
      ubicacion: solicitud.ubicacionNormalizada,
      descripcion: solicitud.descripcionNormalizada.isEmpty
          ? null
          : solicitud.descripcionNormalizada,
      activo: true,
    );
  }
}

class _FakeUsuariosRepository implements UsuariosRepository {
  @override
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud) async {
    return Tecnico(
      id: 1,
      nombreCompleto: solicitud.nombreNormalizado,
      correo: solicitud.correoNormalizado,
      usuario: solicitud.usuarioNormalizado,
      activo: true,
    );
  }
}

void main() {
  testWidgets('la app arranca en el splash y termina en el login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SceiQrApp(
        authRepository: FakeAuthRepository(),
        usuariosRepository: _FakeUsuariosRepository(),
        equiposRepository: _FakeEquiposRepository(),
      ),
    );

    // Splash: muestra logo y spinner mientras restaura la sesión.
    expect(find.text('SCEI QR'), findsOneWidget);

    await tester.pump();
    await tester.pumpAndSettle();

    // Sin sesión persistida → formulario de login.
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}

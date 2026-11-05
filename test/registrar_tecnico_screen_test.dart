import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_tecnico.dart';
import 'package:scei_qr/dominio/tecnico.dart';
import 'package:scei_qr/features/usuarios/domain/repositories/usuarios_repository.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/registrar_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/presentation/screens/registrar_tecnico_screen.dart';

class FakeUsuariosRepository implements UsuariosRepository {
  FakeUsuariosRepository({this.alRegistrar});

  Future<Tecnico> Function(SolicitudAltaTecnico)? alRegistrar;
  int llamadas = 0;
  SolicitudAltaTecnico? ultimaSolicitud;

  @override
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    final handler = alRegistrar;
    if (handler == null) {
      return Tecnico(
        id: 7,
        nombreCompleto: solicitud.nombreNormalizado,
        correo: solicitud.correoNormalizado,
        usuario: solicitud.usuarioNormalizado,
        activo: true,
      );
    }
    return handler(solicitud);
  }
}

void main() {
  Future<void> pump(WidgetTester tester, UsuariosRepository repository) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegistrarTecnicoScreen(
          useCase: RegistrarTecnicoUseCase(repository),
        ),
      ),
    );
  }

  Future<void> llenar(
    WidgetTester tester, {
    String nombre = 'Carlos Mena',
    String correo = 'carlos.mena@utez.edu.mx',
    String usuario = 'cmena',
    String password = 'Password123!',
    String confirmacion = 'Password123!',
  }) async {
    await tester.enterText(
      find.byKey(const Key('tecnico_nombre_field')),
      nombre,
    );
    await tester.enterText(
      find.byKey(const Key('tecnico_correo_field')),
      correo,
    );
    await tester.enterText(
      find.byKey(const Key('tecnico_usuario_field')),
      usuario,
    );
    await tester.enterText(
      find.byKey(const Key('tecnico_password_field')),
      password,
    );
    await tester.enterText(
      find.byKey(const Key('tecnico_confirmacion_field')),
      confirmacion,
    );
  }

  Future<void> enviar(WidgetTester tester) async {
    final boton = find.byKey(const Key('registrar_tecnico_button'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  group('RegistrarTecnicoScreen - HU-AD-02', () {
    testWidgets('muestra todos los campos del alta', (tester) async {
      await pump(tester, FakeUsuariosRepository());

      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Contraseña inicial'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.byKey(const Key('registrar_tecnico_button')), findsOneWidget);
    });

    testWidgets('valida los campos vacíos antes de enviar', (tester) async {
      final repo = FakeUsuariosRepository();
      await pump(tester, repo);

      await enviar(tester);

      expect(find.text('El nombre completo es obligatorio'), findsOneWidget);
      expect(find.text('El correo es obligatorio'), findsOneWidget);
      expect(find.text('El usuario es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña inicial es obligatoria'), findsOneWidget);
      expect(find.text('Confirma la contraseña'), findsOneWidget);
      expect(repo.llamadas, 0);
    });

    testWidgets('rechaza un correo con formato inválido', (tester) async {
      final repo = FakeUsuariosRepository();
      await pump(tester, repo);

      await llenar(tester, correo: 'correo');
      await enviar(tester);

      expect(find.text('El correo no es válido'), findsOneWidget);
      expect(repo.llamadas, 0);
    });

    testWidgets('rechaza contraseñas que no coinciden', (tester) async {
      final repo = FakeUsuariosRepository();
      await pump(tester, repo);

      await llenar(tester, confirmacion: 'OtraPassword123!');
      await enviar(tester);

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(repo.llamadas, 0);
    });

    testWidgets('registra al técnico y muestra confirmación visual', (
      tester,
    ) async {
      final repo = FakeUsuariosRepository();
      await pump(tester, repo);

      await llenar(tester);
      await enviar(tester);

      expect(find.byKey(const Key('registro_exitoso_dialog')), findsOneWidget);
      expect(find.text('Técnico registrado'), findsOneWidget);
      expect(find.textContaining('Carlos Mena'), findsWidgets);
      expect(repo.llamadas, 1);
      expect(repo.ultimaSolicitud!.usuario, 'cmena');
      expect(repo.ultimaSolicitud!.correo, 'carlos.mena@utez.edu.mx');

      await tester.tap(find.byKey(const Key('registro_exitoso_aceptar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('registro_exitoso_dialog')), findsNothing);
      expect(find.text('Carlos Mena'), findsNothing);
    });

    testWidgets('muestra el error del servidor cuando el correo ya existe', (
      tester,
    ) async {
      final repo = FakeUsuariosRepository(
        alRegistrar: (_) async => throw const ConflictException(
          'El correo "carlos.mena@utez.edu.mx" ya existe',
          campo: 'correo',
        ),
      );
      await pump(tester, repo);

      await llenar(tester);
      await enviar(tester);

      expect(find.byKey(const Key('registrar_tecnico_error')), findsOneWidget);
      expect(
        find.text('El correo "carlos.mena@utez.edu.mx" ya existe'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('registro_exitoso_dialog')), findsNothing);
    });
  });
}

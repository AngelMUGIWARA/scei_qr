import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_alumno.dart';
import 'package:scei_qr/dominio/alumno.dart';
import 'package:scei_qr/features/alumnos/domain/repositories/alumnos_repository.dart';
import 'package:scei_qr/features/alumnos/domain/usecases/registrar_alumno_usecase.dart';
import 'package:scei_qr/features/alumnos/presentation/screens/registrar_alumno_screen.dart';

class FakeAlumnosRepository implements AlumnosRepository {
  FakeAlumnosRepository({this.alRegistrar});

  Future<Alumno> Function(SolicitudAltaAlumno)? alRegistrar;
  int llamadas = 0;
  SolicitudAltaAlumno? ultimaSolicitud;

  @override
  Future<Alumno> registrarAlumno(SolicitudAltaAlumno solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    final handler = alRegistrar;
    if (handler == null) {
      return solicitud.aAlumno(fechaAlta: DateTime(2026, 11, 6, 12));
    }
    return handler(solicitud);
  }

  @override
  Future<List<Alumno>> listarAlumnos({String? busqueda, bool? activo}) async {
    return const [];
  }

  @override
  Future<Alumno> cambiarEstado({required int id, required bool activo}) async {
    return Alumno(
      id: id,
      matricula: '20231234',
      nombre: 'Ana López',
      correoInstitucional: 'ana.lopez@universidad.edu.mx',
      usuario: 'ana.lopez@universidad.edu.mx',
      activo: activo,
      fechaAlta: DateTime(2026, 11, 6, 12),
    );
  }
}

void main() {
  Future<void> pump(WidgetTester tester, AlumnosRepository repository) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegistrarAlumnoScreen(
          useCase: RegistrarAlumnoUseCase(repository),
        ),
      ),
    );
  }

  Future<void> llenar(
    WidgetTester tester, {
    String nombre = 'Ana López',
    String matricula = '20231234',
    String correo = 'ana.lopez@universidad.edu.mx',
    String password = 'Password123!',
    String confirmacion = 'Password123!',
  }) async {
    await tester.enterText(
      find.byKey(const Key('alumno_nombre_field')),
      nombre,
    );
    await tester.enterText(
      find.byKey(const Key('alumno_matricula_field')),
      matricula,
    );
    await tester.enterText(
      find.byKey(const Key('alumno_correo_field')),
      correo,
    );
    await tester.enterText(
      find.byKey(const Key('alumno_password_field')),
      password,
    );
    await tester.enterText(
      find.byKey(const Key('alumno_confirmacion_field')),
      confirmacion,
    );
  }

  Future<void> enviar(WidgetTester tester) async {
    final boton = find.byKey(const Key('registrar_alumno_button'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
  }

  group('RegistrarAlumnoScreen - HU-AD-12', () {
    testWidgets('muestra todos los campos del alta', (tester) async {
      await pump(tester, FakeAlumnosRepository());

      expect(find.text('Nombre completo'), findsOneWidget);
      expect(find.text('Matrícula'), findsOneWidget);
      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.text('Contraseña inicial'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.byKey(const Key('registrar_alumno_button')), findsOneWidget);
    });

    testWidgets('valida los campos vacíos antes de enviar', (tester) async {
      final repo = FakeAlumnosRepository();
      await pump(tester, repo);

      await enviar(tester);

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('La matrícula es obligatoria'), findsOneWidget);
      expect(
        find.text('El correo institucional es obligatorio'),
        findsOneWidget,
      );
      expect(find.text('La contraseña inicial es obligatoria'), findsOneWidget);
      expect(find.text('Confirma la contraseña'), findsOneWidget);
      expect(repo.llamadas, 0);
    });

    testWidgets('rechaza una matrícula con formato inválido', (tester) async {
      final repo = FakeAlumnosRepository();
      await pump(tester, repo);

      await llenar(tester, matricula: 'abc-def');
      await enviar(tester);

      expect(
        find.text('La matrícula solo admite letras y números'),
        findsOneWidget,
      );
      expect(repo.llamadas, 0);
    });

    testWidgets('rechaza un correo con formato inválido', (tester) async {
      final repo = FakeAlumnosRepository();
      await pump(tester, repo);

      await llenar(tester, correo: 'correo');
      await enviar(tester);

      expect(find.text('El correo institucional no es válido'), findsOneWidget);
      expect(repo.llamadas, 0);
    });

    testWidgets('rechaza contraseñas que no coinciden', (tester) async {
      final repo = FakeAlumnosRepository();
      await pump(tester, repo);

      await llenar(tester, confirmacion: 'OtraPassword123!');
      await enviar(tester);

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(repo.llamadas, 0);
    });

    testWidgets('registra al alumno y muestra confirmación visual', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository();
      await pump(tester, repo);

      await llenar(tester);
      await enviar(tester);

      expect(find.byKey(const Key('alumno_registrado_dialog')), findsOneWidget);
      expect(find.text('Alumno registrado'), findsOneWidget);
      expect(find.textContaining('Ana López'), findsWidgets);
      expect(repo.llamadas, 1);
      // CA HU-AD-12: la credencial es el correo institucional.
      expect(repo.ultimaSolicitud!.usuario, isNull);
      expect(
        repo.ultimaSolicitud!.usuarioNormalizado,
        'ana.lopez@universidad.edu.mx',
      );
      expect(repo.ultimaSolicitud!.matricula, '20231234');

      await tester.tap(find.byKey(const Key('alumno_registrado_aceptar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('alumno_registrado_dialog')), findsNothing);
      expect(find.text('Ana López'), findsNothing);
    });

    testWidgets('muestra el error del servidor cuando la matrícula ya existe', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository(
        alRegistrar: (_) async => throw const ConflictException(
          'La matrícula "20231234" ya existe',
          campo: 'matricula',
        ),
      );
      await pump(tester, repo);

      await llenar(tester);
      await enviar(tester);

      expect(find.byKey(const Key('registrar_alumno_error')), findsOneWidget);
      expect(find.text('La matrícula "20231234" ya existe'), findsOneWidget);
      expect(find.byKey(const Key('alumno_registrado_dialog')), findsNothing);
    });
  });
}

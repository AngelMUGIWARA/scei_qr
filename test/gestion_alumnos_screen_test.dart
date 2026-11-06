import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_alumno.dart';
import 'package:scei_qr/dominio/alumno.dart';
import 'package:scei_qr/features/alumnos/domain/repositories/alumnos_repository.dart';
import 'package:scei_qr/features/alumnos/domain/usecases/cambiar_estado_alumno_usecase.dart';
import 'package:scei_qr/features/alumnos/domain/usecases/listar_alumnos_usecase.dart';
import 'package:scei_qr/features/alumnos/presentation/screens/gestion_alumnos_screen.dart';

class FakeAlumnosRepository implements AlumnosRepository {
  FakeAlumnosRepository({
    this.alListar,
    this.alCambiarEstado,
    this.alumnos = const [],
  });

  Future<List<Alumno>> Function(String? busqueda)? alListar;
  Future<Alumno> Function(int id, bool activo)? alCambiarEstado;
  int listarLlamadas = 0;
  int cambiarLlamadas = 0;
  String? ultimaBusqueda;
  int? ultimoId;
  bool? ultimoActivo;
  List<Alumno> alumnos = const [];

  @override
  Future<Alumno> registrarAlumno(SolicitudAltaAlumno solicitud) async {
    return solicitud.aAlumno(fechaAlta: DateTime(2026, 11, 6, 12));
  }

  @override
  Future<List<Alumno>> listarAlumnos({String? busqueda, bool? activo}) async {
    listarLlamadas++;
    ultimaBusqueda = busqueda;
    final handler = alListar;
    if (handler != null) return handler(busqueda);
    return alumnos;
  }

  @override
  Future<Alumno> cambiarEstado({required int id, required bool activo}) async {
    cambiarLlamadas++;
    ultimoId = id;
    ultimoActivo = activo;
    final handler = alCambiarEstado;
    if (handler != null) return handler(id, activo);
    return _alumno(id: id, activo: activo);
  }

  Alumno _alumno({required int id, required bool activo, String? matricula}) =>
      Alumno(
        id: id,
        matricula: matricula ?? '20231234',
        nombre: 'Ana López',
        correoInstitucional: 'ana.lopez@universidad.edu.mx',
        usuario: 'ana.lopez@universidad.edu.mx',
        activo: activo,
        fechaAlta: DateTime(2026, 11, 6, 12),
      );
}

Alumno alumnoActivo({int id = 1, String matricula = '20231234'}) => Alumno(
  id: id,
  matricula: matricula,
  nombre: 'Ana López',
  correoInstitucional: 'ana.lopez@universidad.edu.mx',
  usuario: 'ana.lopez@universidad.edu.mx',
  activo: true,
  fechaAlta: DateTime(2026, 11, 6, 12),
);

Alumno alumnoDeBaja({int id = 2, String matricula = '20235678'}) => Alumno(
  id: id,
  matricula: matricula,
  nombre: 'Luis Pérez',
  correoInstitucional: 'luis.perez@universidad.edu.mx',
  usuario: 'luis.perez@universidad.edu.mx',
  activo: false,
  fechaAlta: DateTime(2026, 11, 6, 12),
);

void main() {
  Future<void> pump(WidgetTester tester, AlumnosRepository repository) async {
    await tester.pumpWidget(
      Provider<AlumnosRepository>.value(
        value: repository,
        child: MaterialApp(
          home: GestionAlumnosScreen(
            listarUseCase: ListarAlumnosUseCase(repository),
            cambiarUseCase: CambiarEstadoAlumnoUseCase(repository),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('GestionAlumnosScreen - HU-AD-12', () {
    testWidgets('muestra el listado de cuentas, activas y dadas de baja', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository(
        alumnos: [alumnoActivo(), alumnoDeBaja()],
      );
      await pump(tester, repo);

      expect(find.byKey(const Key('alumnos_lista')), findsOneWidget);
      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('Luis Pérez'), findsOneWidget);
      expect(repo.listarLlamadas, 1);
      expect(repo.ultimaBusqueda, isNull);
    });

    testWidgets('incluye la cuenta desactivada con su aviso de historial', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository(alumnos: [alumnoDeBaja()]);
      await pump(tester, repo);

      // CA HU-AD-12: la cuenta de baja se conserva visible en la lista.
      expect(find.text('Luis Pérez'), findsOneWidget);
      expect(find.textContaining('historial conservado'), findsOneWidget);
    });

    testWidgets('busca por matrícula o nombre', (tester) async {
      final repo = FakeAlumnosRepository(alumnos: [alumnoActivo()]);
      await pump(tester, repo);

      await tester.enterText(
        find.byKey(const Key('alumno_busqueda_field')),
        '20231234',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(repo.ultimaBusqueda, '20231234');
      expect(repo.listarLlamadas, 2);
    });

    testWidgets('muestra mensaje vacío cuando no hay coincidencias', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository(alumnos: const []);
      await pump(tester, repo);

      expect(find.byKey(const Key('gestion_alumnos_vacio')), findsOneWidget);
    });

    testWidgets('muestra error y permite reintentar si falla el listado', (
      tester,
    ) async {
      var fallos = 1;
      final repo = FakeAlumnosRepository(
        alListar: (_) async {
          if (fallos > 0) {
            fallos--;
            throw const NetworkException();
          }
          return [alumnoActivo()];
        },
      );
      await pump(tester, repo);

      expect(
        find.byKey(const Key('gestion_alumnos_vacio_error')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('gestion_alumnos_reintentar')));
      await tester.pumpAndSettle();

      expect(find.text('Ana López'), findsOneWidget);
      expect(repo.listarLlamadas, 2);
    });

    testWidgets('confirma la baja lógica antes de desactivar la cuenta', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository(alumnos: [alumnoActivo()]);
      await pump(tester, repo);

      await tester.tap(find.byKey(const Key('alumno_estado_20231234')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cambiar_estado_dialog')), findsOneWidget);
      expect(find.text('Desactivar cuenta'), findsOneWidget);
      expect(
        find.textContaining('historial', findRichText: true),
        findsWidgets,
      );
      // Aún no se ha confirmado: no se manda el cambio.
      expect(repo.cambiarLlamadas, 0);

      await tester.tap(find.byKey(const Key('cambiar_estado_aceptar')));
      await tester.pumpAndSettle();

      expect(repo.cambiarLlamadas, 1);
      expect(repo.ultimoId, 1);
      expect(repo.ultimoActivo, isFalse);
      expect(find.byKey(const Key('cambiar_estado_exito')), findsOneWidget);
      expect(find.textContaining('Desactivada'), findsOneWidget);
    });

    testWidgets('permite reactivar una cuenta dada de baja', (tester) async {
      final repo = FakeAlumnosRepository(alumnos: [alumnoDeBaja()]);
      await pump(tester, repo);

      await tester.tap(find.byKey(const Key('alumno_estado_20235678')));
      await tester.pumpAndSettle();

      expect(find.text('Reactivar cuenta'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cambiar_estado_aceptar')));
      await tester.pumpAndSettle();

      expect(repo.cambiarLlamadas, 1);
      expect(repo.ultimoId, 2);
      expect(repo.ultimoActivo, isTrue);
    });

    testWidgets('no cambia el estado si se cancela el diálogo', (tester) async {
      final repo = FakeAlumnosRepository(alumnos: [alumnoActivo()]);
      await pump(tester, repo);

      await tester.tap(find.byKey(const Key('alumno_estado_20231234')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cambiar_estado_cancelar')));
      await tester.pumpAndSettle();

      expect(repo.cambiarLlamadas, 0);
      expect(find.byKey(const Key('cambiar_estado_dialog')), findsNothing);
    });

    testWidgets('muestra el error si el cambio de estado falla', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository(
        alumnos: [alumnoActivo()],
        alCambiarEstado: (_, _) async =>
            throw const ForbiddenException('No autorizado'),
      );
      await pump(tester, repo);

      await tester.tap(find.byKey(const Key('alumno_estado_20231234')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cambiar_estado_aceptar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gestion_alumnos_error')), findsOneWidget);
      expect(find.text('No autorizado'), findsOneWidget);
      // La cuenta no se marca como desactivada si el servidor rechazó.
      expect(find.textContaining('Desactivada'), findsNothing);
    });

    testWidgets('el botón de alta abre el formulario de registro', (
      tester,
    ) async {
      final repo = FakeAlumnosRepository(alumnos: [alumnoActivo()]);
      await pump(tester, repo);

      await tester.tap(find.byKey(const Key('registrar_alumno_fab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('registrar_alumno_button')), findsOneWidget);
      expect(find.text('Alta de cuenta de alumno'), findsOneWidget);
    });
  });
}

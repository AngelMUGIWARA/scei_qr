import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_alumno.dart';
import 'package:scei_qr/dominio/alumno.dart';
import 'package:scei_qr/features/alumnos/domain/repositories/alumnos_repository.dart';
import 'package:scei_qr/features/alumnos/domain/usecases/cambiar_estado_alumno_usecase.dart';
import 'package:scei_qr/features/alumnos/domain/usecases/registrar_alumno_usecase.dart';

class FakeAlumnosRepository implements AlumnosRepository {
  FakeAlumnosRepository({this.alRegistrar, this.alCambiarEstado});

  Future<Alumno> Function(SolicitudAltaAlumno)? alRegistrar;
  Future<Alumno> Function(int id, bool activo)? alCambiarEstado;
  int registrarLlamadas = 0;
  int cambiarLlamadas = 0;
  SolicitudAltaAlumno? ultimaSolicitud;
  int? ultimoId;
  bool? ultimoActivo;
  List<Alumno> alumnos = const [];

  @override
  Future<Alumno> registrarAlumno(SolicitudAltaAlumno solicitud) async {
    registrarLlamadas++;
    ultimaSolicitud = solicitud;
    final handler = alRegistrar;
    if (handler == null) return _alumnoDePrueba();
    return handler(solicitud);
  }

  @override
  Future<List<Alumno>> listarAlumnos({String? busqueda, bool? activo}) async {
    return alumnos;
  }

  @override
  Future<Alumno> cambiarEstado({required int id, required bool activo}) async {
    cambiarLlamadas++;
    ultimoId = id;
    ultimoActivo = activo;
    final handler = alCambiarEstado;
    if (handler == null) return _alumnoDePrueba(activo: activo);
    return handler(id, activo);
  }

  Alumno _alumnoDePrueba({bool activo = true}) => Alumno(
    id: 42,
    matricula: '20231234',
    nombre: 'Ana López',
    correoInstitucional: 'ana.lopez@universidad.edu.mx',
    usuario: 'ana.lopez@universidad.edu.mx',
    activo: activo,
    fechaAlta: DateTime(2026, 11, 6, 12),
  );
}

final _fechaAlta = DateTime(2026, 11, 6, 12);

void main() {
  const valida = SolicitudAltaAlumno(
    nombre: 'Ana López',
    matricula: '20231234',
    correoInstitucional: 'ana.lopez@universidad.edu.mx',
    contrasenaInicial: 'secreta123',
  );
  group('RegistrarAlumnoUseCase', () {
    test('delega en el repositorio cuando la solicitud es válida', () async {
      final repo = FakeAlumnosRepository();
      final useCase = RegistrarAlumnoUseCase(repo);

      final alumno = await useCase(valida);

      expect(alumno.matricula, '20231234');
      expect(alumno.activo, isTrue);
      expect(repo.registrarLlamadas, 1);
      expect(repo.ultimaSolicitud, same(valida));
    });

    test('no llama al repositorio si falta un dato obligatorio', () async {
      final repo = FakeAlumnosRepository();
      final useCase = RegistrarAlumnoUseCase(repo);

      await expectLater(
        useCase(
          const SolicitudAltaAlumno(
            nombre: '',
            matricula: '',
            correoInstitucional: '',
            contrasenaInicial: '',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(repo.registrarLlamadas, 0);
    });

    test('propaga el conflicto de unicidad de la matrícula', () async {
      final repo = FakeAlumnosRepository(
        alRegistrar: (_) async => throw const ConflictException(
          'La matrícula "20231234" ya existe',
          campo: 'matricula',
        ),
      );
      final useCase = RegistrarAlumnoUseCase(repo);

      await expectLater(
        useCase(valida),
        throwsA(
          isA<ConflictException>().having((e) => e.campo, 'campo', 'matricula'),
        ),
      );
    });
  });

  group('CambiarEstadoAlumnoUseCase', () {
    final conId = Alumno(
      id: 42,
      matricula: '20231234',
      nombre: 'Ana López',
      correoInstitucional: 'ana.lopez@universidad.edu.mx',
      usuario: 'ana.lopez@universidad.edu.mx',
      activo: true,
      fechaAlta: _fechaAlta,
    );

    test('la baja lógica envía activo=false con el id de la cuenta', () async {
      final repo = FakeAlumnosRepository();
      final useCase = CambiarEstadoAlumnoUseCase(repo);

      final alumno = await useCase(conId, activo: false);

      expect(repo.cambiarLlamadas, 1);
      expect(repo.ultimoId, 42);
      expect(repo.ultimoActivo, isFalse);
      expect(alumno.activo, isFalse);
      // CA HU-AD-12: conserva el historial (los datos no cambian).
      expect(alumno.matricula, '20231234');
      expect(alumno.nombre, 'Ana López');
      expect(alumno.fechaAlta, _fechaAlta);
    });

    test('la reactivación envía activo=true', () async {
      final repo = FakeAlumnosRepository();
      final useCase = CambiarEstadoAlumnoUseCase(repo);

      await useCase(conId, activo: true);

      expect(repo.ultimoId, 42);
      expect(repo.ultimoActivo, isTrue);
    });

    test('no llama al repositorio si la cuenta no tiene id', () async {
      final repo = FakeAlumnosRepository();
      final useCase = CambiarEstadoAlumnoUseCase(repo);

      await expectLater(
        useCase(
          Alumno(
            matricula: '20231234',
            nombre: 'Ana López',
            correoInstitucional: 'ana.lopez@universidad.edu.mx',
            usuario: 'ana.lopez@universidad.edu.mx',
            activo: true,
            fechaAlta: _fechaAlta,
          ),
          activo: false,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(repo.cambiarLlamadas, 0);
    });

    test('propaga el error del servidor', () async {
      final repo = FakeAlumnosRepository(
        alCambiarEstado: (_, _) async => throw const ServerException(),
      );
      final useCase = CambiarEstadoAlumnoUseCase(repo);

      await expectLater(
        useCase(conId, activo: false),
        throwsA(isA<ServerException>()),
      );
    });
  });
}

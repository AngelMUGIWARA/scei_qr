import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_alumno.dart';
import 'package:scei_qr/features/alumnos/data/datasources/alumnos_remote_data_source.dart';
import 'package:scei_qr/features/alumnos/data/models/alumno_model.dart';
import 'package:scei_qr/features/alumnos/data/repositories/alumnos_repository_impl.dart';

class FakeRemoteDataSource implements AlumnosRemoteDataSource {
  FakeRemoteDataSource({this.respuesta, this.lista, this.error});

  AlumnoModel? respuesta;
  List<AlumnoModel>? lista;
  Object? error;
  int llamadas = 0;
  SolicitudAltaAlumno? ultimaSolicitud;
  int? ultimoId;
  bool? ultimoActivo;

  @override
  Future<AlumnoModel> registrarAlumno(SolicitudAltaAlumno solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    if (error != null) throw error!;
    return respuesta!;
  }

  @override
  Future<List<AlumnoModel>> listarAlumnos({
    String? busqueda,
    bool? activo,
  }) async {
    llamadas++;
    if (error != null) throw error!;
    return lista ?? const [];
  }

  @override
  Future<AlumnoModel> cambiarEstado({
    required int id,
    required bool activo,
  }) async {
    llamadas++;
    ultimoId = id;
    ultimoActivo = activo;
    if (error != null) throw error!;
    return respuesta!;
  }
}

AlumnoModel modeloAlumno({bool activo = true}) => AlumnoModel(
  id: 42,
  username: 'ana.lopez@universidad.edu.mx',
  fullName: 'Ana López',
  correo: 'ana.lopez@universidad.edu.mx',
  matricula: '20231234',
  rol: 'ALUMNO',
  activo: activo,
  fechaAlta: DateTime(2026, 11, 6, 12),
);

void main() {
  const solicitud = SolicitudAltaAlumno(
    nombre: 'Ana López',
    matricula: '20231234',
    correoInstitucional: 'ana.lopez@universidad.edu.mx',
    contrasenaInicial: 'secreta123',
  );

  test(
    'registrarAlumno mapea el DTO del backend a la entidad de dominio',
    () async {
      final remote = FakeRemoteDataSource(respuesta: modeloAlumno());
      final repo = AlumnosRepositoryImpl(remote);

      final alumno = await repo.registrarAlumno(solicitud);

      expect(alumno.id, 42);
      expect(alumno.matricula, '20231234');
      expect(alumno.nombre, 'Ana López');
      expect(alumno.correoInstitucional, 'ana.lopez@universidad.edu.mx');
      expect(alumno.usuario, 'ana.lopez@universidad.edu.mx');
      expect(alumno.activo, isTrue);
      expect(alumno.fechaAlta, DateTime(2026, 11, 6, 12));
      expect(alumno.fechaBaja, isNull);
      expect(remote.ultimaSolicitud, same(solicitud));
    },
  );

  test('listarAlumnos devuelve todas las cuentas, activas y de baja', () async {
    final remote = FakeRemoteDataSource(
      lista: [modeloAlumno(), modeloAlumno(activo: false)],
    );
    final repo = AlumnosRepositoryImpl(remote);

    final alumnos = await repo.listarAlumnos();

    expect(alumnos, hasLength(2));
    expect(alumnos.first.activo, isTrue);
    expect(alumnos.last.activo, isFalse);
    // CA HU-AD-12: la cuenta de baja conserva sus datos.
    expect(alumnos.last.matricula, '20231234');
    expect(alumnos.last.nombre, 'Ana López');
  });

  test('cambiarEstado delega id y estado en el datasource', () async {
    final remote = FakeRemoteDataSource(respuesta: modeloAlumno(activo: false));
    final repo = AlumnosRepositoryImpl(remote);

    final alumno = await repo.cambiarEstado(id: 42, activo: false);

    expect(remote.ultimoId, 42);
    expect(remote.ultimoActivo, isFalse);
    expect(alumno.activo, isFalse);
    expect(alumno.matricula, '20231234');
  });

  test('propaga el ConflictException del datasource', () async {
    final remote = FakeRemoteDataSource(
      error: const ConflictException(
        'La matrícula "20231234" ya existe',
        campo: 'matricula',
      ),
    );
    final repo = AlumnosRepositoryImpl(remote);

    await expectLater(
      repo.registrarAlumno(solicitud),
      throwsA(
        isA<ConflictException>().having((e) => e.campo, 'campo', 'matricula'),
      ),
    );
  });
}

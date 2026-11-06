import '../../../../dominio/alta_alumno.dart';
import '../../../../dominio/alumno.dart';
import '../../domain/repositories/alumnos_repository.dart';
import '../datasources/alumnos_remote_data_source.dart';

class AlumnosRepositoryImpl implements AlumnosRepository {
  const AlumnosRepositoryImpl(this.remote);

  final AlumnosRemoteDataSource remote;

  @override
  Future<Alumno> registrarAlumno(SolicitudAltaAlumno solicitud) async {
    final model = await remote.registrarAlumno(solicitud);
    return model.toEntity();
  }

  @override
  Future<List<Alumno>> listarAlumnos({String? busqueda, bool? activo}) async {
    final models = await remote.listarAlumnos(
      busqueda: busqueda,
      activo: activo,
    );
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<Alumno> cambiarEstado({required int id, required bool activo}) async {
    final model = await remote.cambiarEstado(id: id, activo: activo);
    return model.toEntity();
  }
}

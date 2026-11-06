import '../../../../dominio/alta_alumno.dart';
import '../models/alumno_model.dart';

abstract class AlumnosRemoteDataSource {
  Future<AlumnoModel> registrarAlumno(SolicitudAltaAlumno solicitud);

  Future<List<AlumnoModel>> listarAlumnos({String? busqueda, bool? activo});

  Future<AlumnoModel> cambiarEstado({required int id, required bool activo});
}

import '../../../../dominio/uso.dart';

abstract class UsosRepository {
  Future<Uso> iniciarUso(String qrToken);

  /// HU-AL-04: uso con estado "ACTIVO" del alumno autenticado, o `null` si
  /// no tiene ninguno (un alumno solo puede tener uno a la vez).
  Future<Uso?> obtenerUsoActivo();

  /// HU-AL-04: finaliza el uso; el servidor asigna la fecha y hora de fin.
  Future<Uso> finalizarUso(int usoId);
}

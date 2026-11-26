import '../models/uso_model.dart';

abstract class UsosRemoteDataSource {
  Future<UsoModel> iniciarUso(String qrToken);

  /// HU-AL-04: `GET /usos/mis-registros` (rol ALUMNO).
  Future<List<UsoModel>> misRegistros();

  /// HU-AL-04: `PATCH /usos/{id}/finalizar` (rol ALUMNO).
  Future<UsoModel> finalizarUso(int usoId);
}

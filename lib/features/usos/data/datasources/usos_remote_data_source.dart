import '../models/uso_model.dart';

abstract class UsosRemoteDataSource {
  Future<UsoModel> iniciarUso(String qrToken, {String? idempotencyKey});
}

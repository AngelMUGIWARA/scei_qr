import '../../../../dominio/uso.dart';
import '../../domain/repositories/usos_repository.dart';
import '../datasources/usos_remote_data_source.dart';

class UsosRepositoryImpl implements UsosRepository {
  const UsosRepositoryImpl(this.remote);

  final UsosRemoteDataSource remote;

  @override
  Future<Uso> iniciarUso(String qrToken, {String? idempotencyKey}) async {
    final model = await remote.iniciarUso(
      qrToken,
      idempotencyKey: idempotencyKey,
    );
    return model.toEntity();
  }
}

import '../../../../dominio/uso.dart';
import '../../domain/repositories/usos_repository.dart';
import '../datasources/usos_remote_data_source.dart';

class UsosRepositoryImpl implements UsosRepository {
  const UsosRepositoryImpl(this.remote);

  final UsosRemoteDataSource remote;

  @override
  Future<Uso> iniciarUso(String qrToken) async {
    final model = await remote.iniciarUso(qrToken);
    return model.toEntity();
  }

  @override
  Future<Uso?> obtenerUsoActivo() async {
    final registros = await remote.misRegistros();
    for (final model in registros) {
      final uso = model.toEntity();
      if (uso.estaActivo) return uso;
    }
    return null;
  }

  @override
  Future<Uso> finalizarUso(int usoId) async {
    final model = await remote.finalizarUso(usoId);
    return model.toEntity();
  }
}

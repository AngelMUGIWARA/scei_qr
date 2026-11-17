import '../../../../dominio/uso.dart';

abstract class UsosRepository {
  Future<Uso> iniciarUso(String qrToken);
}

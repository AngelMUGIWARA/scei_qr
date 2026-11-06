import '../../../../dominio/alta_equipo.dart';
import '../models/equipo_model.dart';

abstract class EquiposRemoteDataSource {
  Future<EquipoModel> registrarEquipo(SolicitudAltaEquipo solicitud);
}

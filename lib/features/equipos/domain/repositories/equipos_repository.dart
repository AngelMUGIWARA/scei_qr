import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/equipo.dart';

abstract class EquiposRepository {
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud);
}

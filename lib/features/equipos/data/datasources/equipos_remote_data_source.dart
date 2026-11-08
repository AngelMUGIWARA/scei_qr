import 'dart:typed_data';

import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/edicion_equipo.dart';
import '../models/equipo_model.dart';

abstract class EquiposRemoteDataSource {
  Future<EquipoModel> registrarEquipo(SolicitudAltaEquipo solicitud);

  Future<List<EquipoModel>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  });

  Future<EquipoModel> obtenerEquipoPorId(int id);

  Future<EquipoModel> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  );

  Future<EquipoModel> cambiarEstadoEquipo(int id, {required bool activo});

  /// HU-AD-06: regenera el `qrToken` del equipo. El token anterior queda
  /// invalidado (deja de resolver en `GET /equipos/qr/{qrToken}`).
  Future<EquipoModel> regenerarQr(int id);

  /// HU-AD-06: bytes del PNG del QR (`GET /equipos/{id}/qr`).
  Future<Uint8List> obtenerImagenQr(int id);

  /// HU-AL-02: resuelve un `qrToken` escaneado (`GET /equipos/qr/{token}`).
  /// 404 cuando el token no existe o el equipo está dado de baja.
  Future<EquipoModel> resolverQr(String qrToken);
}

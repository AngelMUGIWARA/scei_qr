import 'dart:typed_data';

import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/edicion_equipo.dart';
import '../../../../dominio/equipo.dart';

abstract class EquiposRepository {
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud);

  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    String? laboratorio,
    bool? activo,
  });

  Future<Equipo> obtenerEquipoPorId(int id);

  Future<Equipo> actualizarEquipo(int id, SolicitudEdicionEquipo solicitud);

  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo});

  /// HU-AD-06: regenera el QR; el token anterior queda invalidado.
  Future<Equipo> regenerarQr(int id);

  /// HU-AD-06: bytes del PNG del QR del equipo.
  Future<Uint8List> obtenerImagenQr(int id);

  /// HU-AL-02: resuelve un `qrToken` escaneado al equipo que lo tiene
  /// asignado. Lanza [NotFoundException] si el token no existe o si el
  /// equipo está dado de baja.
  Future<Equipo> resolverQr(String qrToken);

  /// HU-AD-07: PDF de la etiqueta individual del equipo.
  Future<Uint8List> descargarEtiquetaQrPdf(int id) =>
      throw UnimplementedError();

  /// HU-AD-07: PDF con las etiquetas de un lote de equipos.
  Future<Uint8List> descargarEtiquetasLote({
    String? laboratorio,
    String? ubicacion,
    bool? activo,
  }) => throw UnimplementedError();
}

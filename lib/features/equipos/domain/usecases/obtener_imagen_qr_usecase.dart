import 'dart:typed_data';

import '../repositories/equipos_repository.dart';

/// HU-AD-06: obtiene los bytes del PNG del QR del equipo para mostrarlo
/// en el detalle (`GET /equipos/{id}/qr`).
class ObtenerImagenQrUseCase {
  const ObtenerImagenQrUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Uint8List> call(int id) => _repository.obtenerImagenQr(id);
}

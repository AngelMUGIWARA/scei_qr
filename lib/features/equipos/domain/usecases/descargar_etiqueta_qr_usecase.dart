import 'dart:typed_data';

import '../repositories/equipos_repository.dart';

/// HU-AD-07: descarga el PDF de la etiqueta individual de un equipo.
class DescargarEtiquetaQrUseCase {
  const DescargarEtiquetaQrUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Uint8List> call(int id) => _repository.descargarEtiquetaQrPdf(id);
}

import 'dart:typed_data';

import '../repositories/equipos_repository.dart';

/// HU-AD-07: descarga el PDF con las etiquetas de un lote de equipos.
class DescargarEtiquetasLoteUseCase {
  const DescargarEtiquetasLoteUseCase(this._repository);

  final EquiposRepository _repository;

  Future<Uint8List> call({
    String? laboratorio,
    String? ubicacion,
    bool? activo,
  }) {
    return _repository.descargarEtiquetasLote(
      laboratorio: laboratorio,
      ubicacion: ubicacion,
      activo: activo,
    );
  }
}

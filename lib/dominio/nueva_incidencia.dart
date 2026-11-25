// CAPA: DOMINIO — Datos para crear una incidencia (HU-AL-06).
//
// Se pasa como parámetro al caso de uso; separa el payload de creación
// de la entidad completa que devuelve el servidor.

import 'incidencia.dart';

class NuevaIncidencia {
  const NuevaIncidencia({
    required this.equipoId,
    required this.tipo,
    required this.descripcion,
  });

  final int equipoId;
  final TipoProblema tipo;

  /// Descripción obligatoria (CA HU-AL-06).
  final String descripcion;
}

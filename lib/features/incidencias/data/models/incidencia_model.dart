import '../../../../dominio/incidencia.dart';

/// Modelo de datos que mapea la respuesta JSON del backend a la entidad
/// [Incidencia] del dominio.
///
/// Contrato real de `POST /incidencias` (serializador `incident_public`):
/// ```json
/// {
///   "id": 1,
///   "equipoId": 3,
///   "reportadaPorId": 7,
///   "atendidaPorId": null,
///   "titulo": "Hardware",
///   "descripcion": "La pantalla parpadea",
///   "fotoUrl": null,
///   "estado": "PENDIENTE",
///   "solucion": null,
///   "creadaEn": "2026-11-25T10:30:00.000Z",
///   "actualizadaEn": "2026-11-25T10:30:00.000Z",
///   "equipo": { "codigo": "PC-LAB1-01", "ubicacion": "Laboratorio 1" },
///   "reportadaPor": { "id": 7, "username": "alumno1", "fullName": "..." },
///   "atendidaPor": null
/// }
/// ```
///
/// El API **no expone `folio`**: se deriva del `id` mientras el backend lo
/// agrega (TODO-PENDIENTE). Tampoco devuelve `tipo`; se recibe por parámetro
/// porque el tipo de problema viaja en el campo `titulo`.
class IncidenciaModel {
  const IncidenciaModel({
    required this.id,
    required this.folio,
    required this.equipoId,
    required this.alumnoId,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.fechaReporte,
    this.equipoIdentificador,
    this.equipoUbicacion,
  });

  final int id;
  final String folio;
  final int equipoId;
  final int alumnoId;
  final TipoProblema tipo;
  final String descripcion;
  final EstadoIncidencia estado;
  final DateTime fechaReporte;
  final String? equipoIdentificador;
  final String? equipoUbicacion;

  factory IncidenciaModel.fromJson(
    Map<String, dynamic> json, {
    TipoProblema? tipo,
  }) {
    final rawId = json['id'];
    final rawEquipoId = json['equipoId'];
    final rawAlumnoId = json['reportadaPorId'];
    final rawDescripcion = json['descripcion'];
    final rawEstado = json['estado'];
    final rawFecha = json['creadaEn'];

    if (rawId is! num ||
        rawEquipoId is! num ||
        rawAlumnoId is! num ||
        rawDescripcion is! String ||
        rawEstado is! String ||
        rawFecha is! String) {
      throw const FormatException('Respuesta de incidencia inválida');
    }

    // Folio: el backend aún no lo devuelve (TODO-PENDIENTE). Se deriva un
    // identificador estable a partir del id del recurso para poder mostrarlo
    // al alumno como folio de seguimiento.
    final rawFolio = json['folio'];
    final folio = rawFolio is String && rawFolio.isNotEmpty
        ? rawFolio
        : 'INC-${rawId.toInt().toString().padLeft(6, '0')}';

    // Datos del equipo embebidos (opcionales).
    String? equipoIdentificador;
    String? equipoUbicacion;
    final rawEquipo = json['equipo'];
    if (rawEquipo is Map<String, dynamic>) {
      final codigo = rawEquipo['codigo'];
      final ubicacion = rawEquipo['ubicacion'];
      equipoIdentificador = codigo is String ? codigo : null;
      equipoUbicacion = ubicacion is String ? ubicacion : null;
    }

    return IncidenciaModel(
      id: rawId.toInt(),
      folio: folio,
      equipoId: rawEquipoId.toInt(),
      alumnoId: rawAlumnoId.toInt(),
      tipo: _resolverTipo(json, tipo),
      descripcion: rawDescripcion,
      estado: EstadoIncidencia.desdeApi(rawEstado),
      fechaReporte: DateTime.parse(rawFecha),
      equipoIdentificador: equipoIdentificador,
      equipoUbicacion: equipoUbicacion,
    );
  }

  /// El API no tiene campo `tipo`: se usa el que envió el usuario; si algún
  /// día el backend lo expone, tiene prioridad.
  static TipoProblema _resolverTipo(
    Map<String, dynamic> json,
    TipoProblema? respaldo,
  ) {
    final rawTipo = json['tipo'];
    if (rawTipo is String && rawTipo.isNotEmpty) {
      return TipoProblema.desdeApi(rawTipo);
    }
    return respaldo ?? TipoProblema.otro;
  }

  Incidencia toEntity() => Incidencia(
        id: id,
        folio: folio,
        equipoId: equipoId,
        alumnoId: alumnoId,
        tipo: tipo,
        descripcion: descripcion,
        estado: estado,
        fechaReporte: fechaReporte,
        equipoIdentificador: equipoIdentificador,
        equipoUbicacion: equipoUbicacion,
      );
}

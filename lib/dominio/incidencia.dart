// CAPA: DOMINIO — Incidencia reportada por un alumno.
//
// HU-AL-06: el alumno reporta una falla en la computadora que usa.
// El sistema crea la incidencia con estado "Pendiente" y devuelve un folio
// de seguimiento.

/// Tipos de problema que el alumno puede reportar (CA HU-AL-06).
enum TipoProblema {
  hardware,
  software,
  red,
  perifericos,
  otro;

  /// Etiqueta visible en la UI.
  String get etiqueta {
    switch (this) {
      case TipoProblema.hardware:
        return 'Hardware';
      case TipoProblema.software:
        return 'Software';
      case TipoProblema.red:
        return 'Red';
      case TipoProblema.perifericos:
        return 'Periféricos';
      case TipoProblema.otro:
        return 'Otro';
    }
  }

  static TipoProblema desdeApi(String valor) {
    switch (valor.toUpperCase()) {
      case 'HARDWARE':
        return TipoProblema.hardware;
      case 'SOFTWARE':
        return TipoProblema.software;
      case 'RED':
        return TipoProblema.red;
      case 'PERIFERICOS':
        return TipoProblema.perifericos;
      default:
        return TipoProblema.otro;
    }
  }
}

/// Estados de una incidencia que el alumno puede ver (README §3).
///
/// Esta iteración solo expone "Pendiente": es el estado con el que se crea
/// el reporte. Los estados que aplicará soporte (en atención / resuelta)
/// se incorporarán cuando el equipo los publique en el API.
enum EstadoIncidencia {
  pendiente;

  /// Etiqueta visible en la UI.
  String get etiqueta => 'Pendiente';

  /// El backend solo devuelve `PENDIENTE` por ahora; cualquier otro valor
  /// se toma como pendiente.
  static EstadoIncidencia desdeApi(String valor) => EstadoIncidencia.pendiente;
}

/// Entidad de dominio que representa una incidencia reportada.
class Incidencia {
  const Incidencia({
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

  /// Folio visible para el alumno (CA HU-AL-06: "Se muestra al alumno un
  /// folio para dar seguimiento al reporte").
  final String folio;

  final int equipoId;
  final int alumnoId;
  final TipoProblema tipo;

  /// Descripción obligatoria del problema (CA HU-AL-06).
  final String descripcion;

  final EstadoIncidencia estado;
  final DateTime fechaReporte;

  // Datos del equipo embebidos para mostrar en confirmación.
  final String? equipoIdentificador;
  final String? equipoUbicacion;
}

// CAPA: DOMINIO — Solicitud de alta de equipo (HU-AD-04).
//
// Restricciones de la historia:
// - No se inventa formato/máscara del identificador: el HU solo exige que sea
//   único (validado por el servidor) y que se reporten errores claros ante
//   datos obligatorios faltantes.
// - No se envía `activo`: el estado inicial "Activo" lo asigna el servidor.
class SolicitudAltaEquipo {
  const SolicitudAltaEquipo({
    required this.identificador,
    required this.laboratorio,
    required this.ubicacion,
    this.descripcion = '',
  });

  final String identificador;

  /// Laboratorio al que pertenece el equipo.
  ///
  /// TODO-PENDIENTE: el contrato `CreateEquipoRequest` no tiene campo para el
  /// laboratorio (`extra="forbid"` rechaza campos fuera del schema). Se
  /// recolecta en el formulario porque el HU lo pide, pero aún no se persiste.
  /// Pendiente de decisión del equipo.
  final String laboratorio;

  /// Ubicación dentro del laboratorio.
  final String ubicacion;

  /// Descripción (marca o modelo). Opcional según el contrato del backend
  /// (`descripcion: str | None = None`).
  final String descripcion;

  String get identificadorNormalizado => identificador.trim();

  String get laboratorioNormalizado => laboratorio.trim();

  String get ubicacionNormalizada => ubicacion.trim();

  String get descripcionNormalizada => descripcion.trim();

  static String? validarIdentificador(String valor) {
    if (valor.trim().isEmpty) {
      return 'El identificador del equipo es obligatorio';
    }
    return null;
  }

  static String? validarLaboratorio(String valor) {
    if (valor.trim().isEmpty) return 'El laboratorio es obligatorio';
    return null;
  }

  static String? validarUbicacion(String valor) {
    if (valor.trim().isEmpty) {
      return 'La ubicación dentro del laboratorio es obligatoria';
    }
    return null;
  }

  List<String> get errores {
    final errores = <String>[];

    void agregar(String? error) {
      if (error != null) errores.add(error);
    }

    agregar(validarIdentificador(identificador));
    agregar(validarLaboratorio(laboratorio));
    agregar(validarUbicacion(ubicacion));
    return errores;
  }

  bool get esValida => errores.isEmpty;
}

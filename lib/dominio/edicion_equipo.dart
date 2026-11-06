// CAPA: DOMINIO — Solicitud de edición de equipo (HU-AD-05).
//
// Solo incluye los campos que el backend actual admite en
// `UpdateEquipoRequest` (scei_qr_api/app/api/schemas.py):
// codigo, nombre, descripcion y ubicacion.
class SolicitudEdicionEquipo {
  const SolicitudEdicionEquipo({
    required this.codigo,
    required this.ubicacion,
    this.nombre = '',
    this.descripcion = '',
  });

  final String codigo;
  final String nombre;
  final String descripcion;
  final String ubicacion;

  String get codigoNormalizado => codigo.trim();

  String get nombreNormalizado => nombre.trim();

  String get descripcionNormalizada => descripcion.trim();

  String get ubicacionNormalizada => ubicacion.trim();

  /// El backend actual exige `nombre` no vacío. HU-AD-04 establece que el
  /// nombre se deriva del código cuando no se proporciona uno.
  String get nombreEfectivo {
    final valor = nombreNormalizado;
    return valor.isEmpty ? codigoNormalizado : valor;
  }

  static String? validarCodigo(String valor) {
    if (valor.trim().isEmpty) {
      return 'El identificador del equipo es obligatorio';
    }
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

    agregar(validarCodigo(codigo));
    agregar(validarUbicacion(ubicacion));
    return errores;
  }

  bool get esValida => errores.isEmpty;
}

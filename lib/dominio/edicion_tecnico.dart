import 'alta_tecnico.dart';

/// Solicitud de edición de los datos de contacto de un técnico (HU-AD-03).
///
/// La contraseña es opcional: solo se envía al backend cuando el
/// administrador decide restablecerla.
class SolicitudEdicionTecnico {
  const SolicitudEdicionTecnico({
    required this.nombreCompleto,
    required this.correo,
    this.contrasenaNueva,
  });

  final String nombreCompleto;
  final String correo;
  final String? contrasenaNueva;

  String get nombreNormalizado => nombreCompleto.trim();

  String get correoNormalizado => correo.trim().toLowerCase();

  /// `true` cuando el administrador capturó una contraseña nueva.
  bool get cambiaContrasena =>
      contrasenaNueva != null && contrasenaNueva!.isNotEmpty;

  /// La contraseña no se recorta: los espacios pueden ser parte de ella.
  String? get contrasenaNuevaLimpia =>
      cambiaContrasena ? contrasenaNueva : null;

  static String? validarNombreCompleto(String nombre) =>
      SolicitudAltaTecnico.validarNombreCompleto(nombre);

  static String? validarCorreo(String correo) =>
      SolicitudAltaTecnico.validarCorreo(correo);

  /// Valida la contraseña nueva solo cuando se capturó algo.
  static String? validarContrasenaNueva(String contrasena) {
    if (contrasena.isEmpty) return null;
    if (contrasena.length < SolicitudAltaTecnico.longitudMinimaContrasena) {
      return 'La nueva contraseña debe tener al menos '
          '${SolicitudAltaTecnico.longitudMinimaContrasena} caracteres';
    }
    return null;
  }

  List<String> get errores {
    final errores = <String>[];

    void agregar(String? error) {
      if (error != null) errores.add(error);
    }

    agregar(validarNombreCompleto(nombreCompleto));
    agregar(validarCorreo(correo));
    if (cambiaContrasena) {
      agregar(validarContrasenaNueva(contrasenaNueva!));
    }
    return errores;
  }

  bool get esValida => errores.isEmpty;
}

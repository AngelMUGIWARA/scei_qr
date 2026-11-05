class SolicitudAltaTecnico {
  const SolicitudAltaTecnico({
    required this.nombreCompleto,
    required this.correo,
    required this.usuario,
    required this.contrasenaInicial,
  });

  final String nombreCompleto;
  final String correo;
  final String usuario;
  final String contrasenaInicial;

  static const int longitudMinimaNombre = 3;
  static const int longitudMinimaUsuario = 4;
  static const int longitudMaximaUsuario = 64;
  static const int longitudMinimaContrasena = 8;

  static final RegExp _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _formatoUsuario = RegExp(r'^[A-Za-z0-9._@-]+$');

  String get nombreNormalizado => nombreCompleto.trim();

  String get correoNormalizado => correo.trim().toLowerCase();

  String get usuarioNormalizado => usuario.trim();

  static String? validarNombreCompleto(String nombre) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'El nombre completo es obligatorio';
    if (limpio.length < longitudMinimaNombre) {
      return 'El nombre debe tener al menos $longitudMinimaNombre caracteres';
    }
    return null;
  }

  static String? validarCorreo(String correo) {
    final limpio = correo.trim();
    if (limpio.isEmpty) return 'El correo es obligatorio';
    if (!_formatoCorreo.hasMatch(limpio)) return 'El correo no es válido';
    return null;
  }

  static String? validarUsuario(String usuario) {
    final limpio = usuario.trim();
    if (limpio.isEmpty) return 'El usuario es obligatorio';
    if (limpio.length < longitudMinimaUsuario ||
        limpio.length > longitudMaximaUsuario) {
      return 'El usuario debe tener entre $longitudMinimaUsuario y '
          '$longitudMaximaUsuario caracteres';
    }
    if (!_formatoUsuario.hasMatch(limpio)) {
      return 'El usuario solo admite letras, números, arroba, punto, guion y '
          'guion bajo';
    }
    return null;
  }

  static String? validarContrasena(String contrasena) {
    if (contrasena.isEmpty) return 'La contraseña inicial es obligatoria';
    if (contrasena.length < longitudMinimaContrasena) {
      return 'La contraseña inicial debe tener al menos '
          '$longitudMinimaContrasena caracteres';
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
    agregar(validarUsuario(usuario));
    agregar(validarContrasena(contrasenaInicial));
    return errores;
  }

  bool get esValida => errores.isEmpty;
}

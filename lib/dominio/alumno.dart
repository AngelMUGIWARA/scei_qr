// CAPA: DOMINIO — Alumno
// Modelo de la cuenta de alumno (HU-AD-12). Sin imports de Flutter.
// La matrícula y el correo institucional son únicos en el backend; la app
// solo valida el formato antes de enviar el alta.
// La baja es lógica: la cuenta deja de poder iniciar sesión, pero sus datos
// permanecen para conservar el historial de uso.

class Alumno {
  const Alumno({
    required this.matricula,
    required this.nombre,
    required this.correoInstitucional,
    required this.usuario,
    required this.activo,
    required this.fechaAlta,
    this.fechaBaja,
  });

  final String matricula;
  final String nombre;
  final String correoInstitucional;
  final String usuario;
  final bool activo;
  final DateTime fechaAlta;
  final DateTime? fechaBaja;

  bool get puedeIniciarSesion => activo;

  bool get estaDadoDeBaja => !activo;

  /// Baja lógica: conserva los datos y solo marca la cuenta como inactiva.
  Alumno darDeBaja(DateTime fecha) => Alumno(
    matricula: matricula,
    nombre: nombre,
    correoInstitucional: correoInstitucional,
    usuario: usuario,
    activo: false,
    fechaAlta: fechaAlta,
    fechaBaja: fecha,
  );

  /// Reactiva una cuenta dada de baja sin tocar sus datos históricos.
  Alumno reactivar() => Alumno(
    matricula: matricula,
    nombre: nombre,
    correoInstitucional: correoInstitucional,
    usuario: usuario,
    activo: true,
    fechaAlta: fechaAlta,
  );

  static const int longitudMinimaMatricula = 6;
  static const int longitudMaximaMatricula = 12;
  static const int longitudMinimaContrasena = 8;

  static final RegExp _formatoMatricula = RegExp(r'^[A-Z0-9]+$');
  static final RegExp _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _formatoUsuario = RegExp(r'^[A-Za-z0-9._@-]{4,64}$');

  static String? validarNombre(String nombre) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'El nombre es obligatorio';
    if (limpio.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? validarMatricula(String matricula) {
    final limpia = matricula.trim().toUpperCase();
    if (limpia.isEmpty) return 'La matrícula es obligatoria';
    if (limpia.length < longitudMinimaMatricula ||
        limpia.length > longitudMaximaMatricula) {
      return 'La matrícula debe tener entre $longitudMinimaMatricula y '
          '$longitudMaximaMatricula caracteres';
    }
    if (!_formatoMatricula.hasMatch(limpia)) {
      return 'La matrícula solo admite letras y números';
    }
    return null;
  }

  static String? validarCorreoInstitucional(String correo) {
    final limpio = correo.trim();
    if (limpio.isEmpty) return 'El correo institucional es obligatorio';
    if (!_formatoCorreo.hasMatch(limpio)) {
      return 'El correo institucional no es válido';
    }
    return null;
  }

  static String? validarUsuario(String usuario) {
    final limpio = usuario.trim();
    if (limpio.isEmpty) return 'El usuario es obligatorio';
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
}

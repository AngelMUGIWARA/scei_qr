// CAPA: DOMINIO — Definición del alta de alumnos (HU-AD-12)
// Sin imports de Flutter.
// Decisión para la iteración 2: el administrador captura cada alumno de
// forma individual. La carga masiva y la integración con el sistema escolar
// quedan fuera de alcance hasta que el equipo las planifique.
// La credencial de acceso es el correo institucional; la matrícula es el
// identificador académico único.

import 'alumno.dart';
import 'rol.dart';

enum MecanismoAlta { capturaIndividual, cargaMasiva, integracionSistemaEscolar }

class DefinicionAltaAlumno {
  const DefinicionAltaAlumno({
    required this.mecanismo,
    required this.rolResponsable,
    required this.identificador,
    required this.credencial,
    required this.permiteAutoregistro,
    required this.permiteCargaMasiva,
  });

  final MecanismoAlta mecanismo;
  final Rol rolResponsable;
  final String identificador;
  final String credencial;
  final bool permiteAutoregistro;
  final bool permiteCargaMasiva;

  String get descripcion => switch (mecanismo) {
    MecanismoAlta.capturaIndividual =>
      'El administrador captura cada alumno desde el formulario de alta.',
    MecanismoAlta.cargaMasiva =>
      'El administrador importa un archivo con varios alumnos.',
    MecanismoAlta.integracionSistemaEscolar =>
      'El sistema escolar sincroniza las cuentas de los alumnos.',
  };
}

const definicionAltaAlumno = DefinicionAltaAlumno(
  mecanismo: MecanismoAlta.capturaIndividual,
  rolResponsable: Rol.administrador,
  identificador: 'matrícula',
  credencial: 'correo institucional',
  permiteAutoregistro: false,
  permiteCargaMasiva: false,
);

class SolicitudAltaAlumno {
  const SolicitudAltaAlumno({
    required this.nombre,
    required this.matricula,
    required this.correoInstitucional,
    required this.contrasenaInicial,
    this.usuario,
  });

  final String nombre;
  final String matricula;
  final String correoInstitucional;
  final String contrasenaInicial;

  /// Si no se indica un usuario, se usa el correo institucional.
  final String? usuario;

  String get matriculaNormalizada => matricula.trim().toUpperCase();

  String get correoNormalizado => correoInstitucional.trim().toLowerCase();

  String get usuarioNormalizado {
    final solicitado = usuario?.trim();
    if (solicitado == null || solicitado.isEmpty) return correoNormalizado;
    return solicitado.toLowerCase();
  }

  List<String> get errores {
    final errores = <String>[];

    void agregar(String? error) {
      if (error != null) errores.add(error);
    }

    agregar(Alumno.validarNombre(nombre));
    agregar(Alumno.validarMatricula(matricula));
    agregar(Alumno.validarCorreoInstitucional(correoInstitucional));
    agregar(Alumno.validarUsuario(usuarioNormalizado));
    agregar(Alumno.validarContrasena(contrasenaInicial));
    return errores;
  }

  bool get esValida => errores.isEmpty;

  Alumno aAlumno({required DateTime fechaAlta}) {
    final problemas = errores;
    if (problemas.isNotEmpty) {
      throw ArgumentError(problemas.join(' '));
    }

    return Alumno(
      matricula: matriculaNormalizada,
      nombre: nombre.trim(),
      correoInstitucional: correoNormalizado,
      usuario: usuarioNormalizado,
      activo: true,
      fechaAlta: fechaAlta,
    );
  }
}

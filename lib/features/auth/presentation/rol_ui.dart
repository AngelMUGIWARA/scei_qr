import '../../../dominio/rol.dart';

/// Traducciones de [Rol] hacia la UI: ruta principal y etiqueta visible.
extension RolUi on Rol {
  /// Ruta interna a la pantalla principal del rol (HU-GEN-01, lado cliente).
  String get rutaHome => switch (this) {
    Rol.soporteTecnico => '/home/soporte',
    Rol.administrador => '/home/admin',
    Rol.alumno => '/home/alumno',
  };

  /// Nombre del rol para mostrar en la UI.
  String get etiqueta => switch (this) {
    Rol.soporteTecnico => 'Soporte técnico',
    Rol.administrador => 'Administrador',
    Rol.alumno => 'Alumno',
  };
}

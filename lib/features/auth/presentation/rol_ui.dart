import '../../../dominio/permiso.dart';
import '../../../dominio/rol.dart';

/// Traducciones de [Rol] hacia la UI: ruta principal, permiso de entrada y
/// etiqueta visible.
extension RolUi on Rol {
  /// Ruta interna a la pantalla principal del rol (HU-GEN-01, lado cliente).
  /// Es la misma para todos los roles: [HomeScreen] decide el contenido.
  String get rutaHome => '/home';

  /// Permiso mínimo que exige la pantalla principal de cada rol.
  /// Usa la matriz de [ReglaAcceso] en lugar de validar el rol en la capa
  /// de datos (el chequeo por rol vive en un solo lugar: el dominio).
  Permiso get permisoHome => switch (this) {
    Rol.alumno => Permiso.registrarUso,
    Rol.soporteTecnico => Permiso.atenderIncidencia,
    Rol.administrador => Permiso.administrarEquipos,
  };

  /// Nombre del rol para mostrar en la UI.
  String get etiqueta => switch (this) {
    Rol.soporteTecnico => 'Soporte técnico',
    Rol.administrador => 'Administrador',
    Rol.alumno => 'Alumno',
  };
}

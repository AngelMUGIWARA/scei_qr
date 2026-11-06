/// HU-AL-02: abstracción del permiso de cámara para que el provider se
/// pueda probar sin el plugin `permission_handler` (que requiere dispositivo
/// o emulador).
abstract class PermisoCamara {
  /// `true` si el permiso ya está concedido (sin pedirlo).
  Future<bool> estaConcedido();

  /// Solicita el permiso en runtime. Devuelve `true` si quedó concedido.
  Future<bool> solicitar();

  /// Abre los ajustes de la aplicación para que el usuario lo habilite
  /// manualmente (caso "denegado permanentemente").
  Future<bool> abrirAjustes();
}

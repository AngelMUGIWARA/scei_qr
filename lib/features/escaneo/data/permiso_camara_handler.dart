import 'package:permission_handler/permission_handler.dart';

import '../domain/permiso_camara.dart';

/// Implementación real de [PermisoCamara] con `permission_handler`.
class PermisoCamaraHandler implements PermisoCamara {
  const PermisoCamaraHandler();

  @override
  Future<bool> estaConcedido() async => (await Permission.camera.status).isGranted;

  @override
  Future<bool> solicitar() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return true;
    // En iOS "denegado" puede volver a pedirse; en Android, tras negar dos
    // veces queda "permanentlyDenied" y toca abrir ajustes.
    if (status.isDenied) {
      return (await Permission.camera.request()).isGranted;
    }
    return false;
  }

  @override
  Future<bool> abrirAjustes() => openAppSettings();
}

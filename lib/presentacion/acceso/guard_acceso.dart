import '../../dominio/permiso.dart';
import '../../dominio/regla_acceso.dart';
import '../../dominio/sesion.dart';

class AccesoDenegado implements Exception {
  const AccesoDenegado(this.motivo);

  final String motivo;

  @override
  String toString() => motivo;
}

class GuardAcceso {
  GuardAcceso({
    required this.sesion,
    DateTime Function()? ahora,
  }) : ahora = ahora ?? DateTime.now;

  final Sesion? Function() sesion;
  final DateTime Function() ahora;

  String? motivoPara(Permiso permiso) =>
      ReglaAcceso.validarSesion(sesion(), permiso, ahora());

  bool permite(Permiso permiso) => motivoPara(permiso) == null;

  void exigir(Permiso permiso) {
    final motivo = motivoPara(permiso);
    if (motivo != null) throw AccesoDenegado(motivo);
  }
}

// CAPA: DOMINIO — Regla de acceso por rol
// Devuelve el motivo del rechazo,
// o null si el acceso está permitido.
// Esta matriz refleja los @Roles(...) de la API; la validación real
// siempre ocurre también en el servidor.
// La propiedad del recurso ("solo mis registros") la valida el servidor
// y los casos de uso, no esta regla.

import 'permiso.dart';
import 'rol.dart';
import 'sesion.dart';

class ReglaAcceso {
  static const Map<Rol, Set<Permiso>> _permisosPorRol = {
    Rol.alumno: {
      Permiso.registrarUso,
      Permiso.consultarMisRegistros,
      Permiso.reportarIncidencia,
      Permiso.consultarMisReportes,
    },
    Rol.soporteTecnico: {
      Permiso.atenderIncidencia,
      Permiso.escanearQrSitio,
      Permiso.consultarIncidencias,
      Permiso.consultarHistorialIncidencias,
    },
    Rol.administrador: {
      Permiso.consultarIncidencias,
      Permiso.consultarHistorialIncidencias,
      Permiso.administrarSoporte,
      Permiso.gestionarAlumnos,
      Permiso.administrarEquipos,
      Permiso.gestionarQr,
      Permiso.consultarHistorialUso,
      Permiso.consultarEstadisticas,
      Permiso.exportarReportes,
    },
  };

  /// Devuelve el motivo del rechazo, o null si el rol tiene el permiso.
  static String? validar(Rol? rol, Permiso permiso) {
    if (rol == null) return 'Inicia sesión para continuar';
    if (!_permisosPorRol[rol]!.contains(permiso)) {
      return 'No tienes permiso para esta acción';
    }
    return null;
  }

  /// Igual que [validar], pero además revisa que la sesión exista y siga
  /// vigente. Es lo que usará el guard de la app.
  static String? validarSesion(
      Sesion? sesion,
      Permiso permiso,
      DateTime ahora,
      ) {
    if (sesion == null) return 'Inicia sesión para continuar';
    if (!sesion.estaVigente(ahora)) {
      return 'Tu sesión expiró, inicia sesión de nuevo';
    }
    return validar(sesion.rol, permiso);
  }
}
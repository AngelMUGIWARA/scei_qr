// CAPA: DOMINIO — Permisos del sistema
// Un permiso por capacidad. Iniciar sesión, cerrar sesión, registrar el
// token de notificaciones y resolver el QR de un equipo los puede hacer
// cualquier usuario autenticado, por eso no son permisos.

enum Permiso {
  // Alumno
  registrarUso, // iniciar y finalizar uso de un equipo
  consultarMisRegistros,
  reportarIncidencia,
  consultarMisReportes,
  // Soporte técnico
  atenderIncidencia, // tomar, cambiar estado y registrar solución
  escanearQrSitio,
  // Soporte técnico y administrador
  consultarIncidencias,
  consultarHistorialIncidencias,
  // Administrador
  administrarSoporte,
  gestionarAlumnos,
  administrarEquipos,
  gestionarQr,
  consultarHistorialUso,
  consultarEstadisticas,
  exportarReportes,
}
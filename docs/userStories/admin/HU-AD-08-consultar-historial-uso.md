# HU-AD-08: Consultar el historial de uso de los equipos

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | `HU-AL-03` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** consultar los registros de uso de las computadoras,  
**para** supervisar quién utiliza los equipos, cuándo y por cuánto tiempo.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra una tabla con equipo, laboratorio, alumno, fecha, hora de inicio, hora de fin y duración.
- [ ] Se puede filtrar por rango de fechas, laboratorio, equipo y alumno.
- [ ] La tabla tiene paginación y ordenamiento por columnas.
- [ ] Los datos coinciden con los registros creados desde la aplicación móvil.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de consulta de registros de uso con filtros (fecha, laboratorio, equipo, alumno).
- [ ] Tabla con paginación y ordenamiento en el panel web.
- [ ] Pruebas de consistencia con los datos generados desde la app móvil.

# HU-AD-09: Consultar y supervisar las incidencias

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | `HU-AL-06`, `HU-ST-05` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** ver todas las incidencias del sistema y su avance,  
**para** supervisar la atención del soporte técnico e identificar retrasos.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra una tabla con folio, equipo, laboratorio, alumno, técnico asignado, estado y fechas.
- [ ] Se puede filtrar por estado, laboratorio, técnico y rango de fechas.
- [ ] El detalle muestra descripción, historial de estados y solución aplicada.
- [ ] Se distinguen visualmente las incidencias pendientes por más tiempo.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de consulta de incidencias con filtros (estado, laboratorio, técnico, fecha).
- [ ] Tabla con detalle expandible (descripción, historial, solución).
- [ ] Resaltar visualmente las incidencias con mayor tiempo pendiente.

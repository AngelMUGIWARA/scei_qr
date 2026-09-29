# HU-AL-07: Consultar el estado de mis reportes

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 3 |
| **Dependencias** | `HU-AL-06`, `HU-ST-05` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** ver el estado actual de las incidencias que he reportado,  
**para** saber si ya están siendo atendidas o si ya fueron resueltas.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra la lista de reportes del alumno con folio, equipo, fecha y estado actual.
- [ ] El detalle de un reporte muestra la descripción, el historial de cambios de estado y, si existe, la solución aplicada.
- [ ] El estado mostrado coincide con el que registró el soporte técnico.
- [ ] Se puede actualizar la lista manualmente (deslizar para refrescar).

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de listado de incidencias por alumno con su estado actual.
- [ ] Pantalla de detalle con historial de cambios de estado.
- [ ] Implementar refresco manual (pull-to-refresh) de la lista.
- [ ] Pruebas de sincronización de estado entre la app y el backend.

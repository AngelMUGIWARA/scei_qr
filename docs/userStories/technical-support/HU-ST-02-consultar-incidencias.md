# HU-ST-02: Consultar las incidencias reportadas

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 3 |
| **Dependencias** | `HU-ST-01`, `HU-AL-06` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** ver la lista de incidencias reportadas por los alumnos,  
**para** conocer qué problemas hay pendientes de atender.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra una lista con folio, equipo, laboratorio, tipo de problema, fecha y estado.
- [ ] Las incidencias pendientes aparecen primero, ordenadas de la más antigua a la más reciente.
- [ ] Se puede filtrar por estado, laboratorio y fecha.
- [ ] La lista se puede actualizar manualmente para ver incidencias nuevas.
- [ ] Cuando no hay incidencias se muestra un mensaje informativo.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de listado de incidencias con filtros por estado, laboratorio y fecha.
- [ ] Implementar el ordenamiento por antigüedad/estado en la UI.
- [ ] Agregar refresco manual de la lista.
- [ ] Manejar el estado vacío (sin incidencias).

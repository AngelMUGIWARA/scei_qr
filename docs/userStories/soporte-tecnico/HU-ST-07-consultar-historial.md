# HU-ST-07: Consultar el historial de incidencias atendidas

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Media |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | `HU-ST-06` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** consultar las incidencias que he atendido anteriormente,  
**para** tener referencia de problemas y soluciones similares.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra la lista de incidencias resueltas por el técnico, con fecha, equipo y solución.
- [ ] Se puede filtrar por fecha y laboratorio, y buscar por folio o equipo.
- [ ] Al seleccionar una incidencia se muestra su detalle completo.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de historial de incidencias resueltas por técnico.
- [ ] Filtros por fecha y laboratorio, y búsqueda por folio o equipo.
- [ ] Reutilizar el componente de detalle de incidencia para esta vista.

# HU-ST-04: Tomar una incidencia para su atención

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 3 |
| **Dependencias** | `HU-ST-03` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** tomar una incidencia pendiente y asignármela,  
**para** que quede claro quién la atiende y evitar que dos técnicos trabajen en la misma.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Solo se pueden tomar incidencias en estado "Pendiente".
- [ ] Al tomarla, el estado cambia a "En atención" y se guarda el técnico asignado, con fecha y hora.
- [ ] Si otro técnico la tomó primero, se informa y no se duplica la asignación.
- [ ] La incidencia tomada aparece en la sección "Mis incidencias".

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint para asignar un técnico a la incidencia (cambia a "En atención").
- [ ] Control de concurrencia para evitar que dos técnicos tomen la misma incidencia.
- [ ] Sección "Mis incidencias" filtrada por técnico asignado.
- [ ] Pruebas de condición de carrera al tomar una incidencia.

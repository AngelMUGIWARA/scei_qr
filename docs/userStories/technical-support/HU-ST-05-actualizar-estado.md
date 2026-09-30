# HU-ST-05: Actualizar el estado de una incidencia

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 3 |
| **Dependencias** | `HU-ST-04` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** actualizar el estado de la incidencia que estoy atendiendo,  
**para** mantener informados a los alumnos y al administrador sobre el avance.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Los estados disponibles son "Pendiente", "En atención" y "Resuelta".
- [ ] Solo el técnico asignado puede cambiar el estado de la incidencia.
- [ ] Cada cambio guarda estado anterior, estado nuevo, técnico, fecha y hora.
- [ ] El alumno que reportó y el administrador ven el nuevo estado al consultar la incidencia.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de transición de estados con validación de reglas permitidas.
- [ ] Registrar el historial de cambios (estado anterior, nuevo, técnico, fecha y hora).
- [ ] Restringir el cambio de estado solo al técnico asignado.
- [ ] Propagar el nuevo estado a las consultas del alumno y del administrador.

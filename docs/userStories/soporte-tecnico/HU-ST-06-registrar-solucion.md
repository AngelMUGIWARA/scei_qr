# HU-ST-06: Registrar la solución aplicada

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 3 |
| **Dependencias** | `HU-ST-05` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** registrar la solución que apliqué a una incidencia,  
**para** dejar constancia del trabajo realizado y poder consultarlo después.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Para marcar una incidencia como "Resuelta" es obligatorio escribir la solución aplicada.
- [ ] Se guarda la fecha y hora de resolución junto con la solución.
- [ ] La solución es visible para el alumno que reportó y para el administrador.
- [ ] No se puede editar la solución una vez cerrada la incidencia, salvo que se registre como una nueva nota.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Hacer obligatorio el campo de solución al marcar la incidencia como "Resuelta".
- [ ] Guardar la fecha y hora de resolución.
- [ ] Mostrar la solución en el detalle visible para alumno y administrador.
- [ ] Definir el mecanismo para agregar notas adicionales tras el cierre.

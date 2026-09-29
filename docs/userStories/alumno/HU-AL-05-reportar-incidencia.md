# HU-AL-06: Reportar una incidencia de un equipo

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 3 |
| **Dependencias** | `HU-AL-01`, `HU-AL-02` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** reportar una falla o problema en la computadora que estoy utilizando,  
**para** que el personal de soporte técnico pueda atenderlo.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] El reporte se inicia desde el equipo escaneado o desde el registro de uso activo, con el equipo ya identificado.
- [ ] El formulario solicita tipo de problema (hardware, software, red, periféricos u otro) y una descripción obligatoria.
- [ ] Al enviar, se crea la incidencia con estado "Pendiente", fecha, hora, equipo y alumno que la reporta.
- [ ] Se muestra al alumno un folio para dar seguimiento al reporte.
- [ ] No se puede enviar el reporte si faltan campos obligatorios.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Implementar formulario de reporte con tipo de problema y descripción.
- [ ] Endpoint para crear la incidencia con estado inicial "Pendiente".
- [ ] Vincular la incidencia con el equipo y el alumno automáticamente.
- [ ] Generar y mostrar el folio de seguimiento al enviar el reporte.
- [ ] Validaciones de campos obligatorios antes de enviar.

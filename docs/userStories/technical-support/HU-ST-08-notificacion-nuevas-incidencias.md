# HU-ST-08: Recibir notificación de nuevas incidencias

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Media |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 5 |
| **Dependencias** | `HU-AL-06` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** recibir una notificación cuando un alumno reporte una nueva incidencia,  
**para** atenderla con rapidez aunque no tenga la aplicación abierta.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se envía una notificación al soporte técnico cuando se crea una incidencia nueva.
- [ ] La notificación indica equipo y laboratorio.
- [ ] Al tocarla se abre el detalle de la incidencia.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Disparar notificación push al crearse una incidencia nueva.
- [ ] Incluir equipo y laboratorio en el contenido de la notificación.
- [ ] Manejar la navegación al detalle desde la notificación.

---

> **Nota:** El documento indica que el soporte "podrá recibirla"; esta historia detalla esa recepción.

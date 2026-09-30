# HU-AL-09: Recibir notificación de cambio de estado

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Baja |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 5 |
| **Dependencias** | `HU-AL-07`, `HU-ST-05` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** recibir una notificación cuando cambie el estado de mi reporte,  
**para** enterarme sin tener que abrir la aplicación para revisarlo.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se envía una notificación cuando la incidencia pasa a "En atención" y cuando pasa a "Resuelta".
- [ ] Al tocar la notificación se abre el detalle del reporte correspondiente.
- [ ] El alumno solo recibe notificaciones de sus propios reportes.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Configurar el servicio de notificaciones push (FCM/APNs).
- [ ] Disparar notificación al cambiar el estado a "En atención" y a "Resuelta".
- [ ] Manejar la navegación al detalle del reporte desde la notificación.
- [ ] Filtrar las notificaciones para que solo lleguen al alumno propietario del reporte.

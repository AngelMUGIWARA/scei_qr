# HU-ST-03: Identificar la computadora y su ubicación

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 3 |
| **Dependencias** | `HU-ST-02` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** ver el detalle de una incidencia junto con la computadora y su ubicación,  
**para** llegar directamente al equipo afectado y atenderlo más rápido.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] El detalle muestra descripción, tipo de problema, alumno que reportó, fecha, hora y estado.
- [ ] También se muestran los datos del equipo: identificador, laboratorio y ubicación dentro del laboratorio.
- [ ] Se muestra el historial de cambios de estado de la incidencia.
- [ ] Si existe una foto adjunta, se puede visualizar.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de detalle de incidencia con datos del equipo y su ubicación.
- [ ] Pantalla de detalle con historial de cambios de estado.
- [ ] Mostrar la imagen adjunta cuando exista.

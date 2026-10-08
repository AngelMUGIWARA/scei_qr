# HU-AL-08: Adjuntar una foto al reporte

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Baja |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 5 |
| **Dependencias** | `HU-AL-06` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** adjuntar una fotografía al reportar una incidencia,  
**para** que el técnico entienda mejor el problema antes de llegar al equipo.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] El formulario de reporte permite adjuntar una imagen de forma opcional.
- [ ] Se puede tomar la foto con la cámara o elegirla de la galería.
- [ ] Se valida el tamaño y formato de la imagen antes de enviarla.
- [ ] El soporte técnico y el administrador pueden ver la imagen en el detalle de la incidencia.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Integrar selector de cámara/galería en el formulario de reporte.
- [ ] Validar tamaño y formato de la imagen antes de subirla.
- [ ] Definir almacenamiento (endpoint/bucket) para adjuntos de incidencia.
- [ ] Mostrar la imagen adjunta en el detalle para alumno, soporte y administrador.

---

> **Nota:** Mejora opcional fuera del alcance base del documento del proyecto.

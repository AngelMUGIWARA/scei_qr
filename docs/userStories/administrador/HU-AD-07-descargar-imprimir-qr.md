# HU-AD-07: Descargar e imprimir los códigos QR

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Media |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | `HU-AD-06` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** descargar o imprimir los códigos QR de los equipos,  
**para** pegarlos físicamente en cada computadora.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se puede descargar el QR de un equipo como imagen o PDF.
- [ ] Se pueden generar etiquetas por lote, por ejemplo todos los equipos de un laboratorio.
- [ ] Cada etiqueta incluye el QR y el identificador legible del equipo.
- [ ] El tamaño de la etiqueta permite escanearla sin dificultad desde el teléfono.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Función de exportación del QR como imagen o PDF.
- [ ] Generación de etiquetas por lote (por laboratorio).
- [ ] Definir la plantilla de etiqueta con QR e identificador legible.

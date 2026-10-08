# HU-ST-09: Escanear el QR del equipo en sitio

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Baja |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 5 |
| **Dependencias** | `HU-ST-04` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** escanear el código QR de la computadora cuando llego al laboratorio,  
**para** confirmar que atiendo el equipo correcto y ver sus incidencias abiertas.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Al escanear un QR válido se muestran los datos del equipo y sus incidencias abiertas.
- [ ] Si el equipo tiene una incidencia pendiente, se ofrece tomarla directamente.
- [ ] Un QR inválido muestra un mensaje claro y permite reintentar.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Reutilizar el componente de escaneo QR de la app de alumno.
- [ ] Endpoint para consultar equipo e incidencias abiertas a partir del QR.
- [ ] Agregar la acción rápida "tomar incidencia" desde el resultado del escaneo.

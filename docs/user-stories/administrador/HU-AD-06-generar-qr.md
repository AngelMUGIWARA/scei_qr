# HU-AD-06: Generar el código QR único de cada equipo

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 1 |
| **Dependencias** | `HU-AD-04` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** que el sistema genere un código QR único para cada computadora,  
**para** que los alumnos y técnicos puedan identificarla desde la aplicación móvil.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Al registrar un equipo se genera automáticamente su QR.
- [ ] El QR codifica un identificador estable y único que no cambia al editar el equipo.
- [ ] Dos equipos nunca comparten el mismo QR.
- [ ] Se puede visualizar el QR en el detalle del equipo.
- [ ] Si el QR se regenera, el anterior deja de ser válido y se informa al administrador.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Generar identificador único y código QR al crear el equipo.
- [ ] Implementar el servicio de generación de QR.
- [ ] Mostrar el QR en el detalle del equipo.
- [ ] Implementar la regeneración de QR invalidando el anterior.

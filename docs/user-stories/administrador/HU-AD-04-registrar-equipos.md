# HU-AD-04: Registrar equipos de cómputo

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 1 |
| **Dependencias** | `HU-AD-01` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** registrar cada computadora de los laboratorios,  
**para** tener un inventario de equipos vinculado al sistema de uso e incidencias.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] El formulario solicita identificador del equipo, laboratorio, ubicación dentro del laboratorio y descripción (marca o modelo).
- [ ] El identificador del equipo debe ser único.
- [ ] Al guardar, el equipo queda con estado "Activo".
- [ ] Se muestran errores claros cuando faltan datos obligatorios.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Formulario de alta de equipo (identificador, laboratorio, ubicación, descripción).
- [ ] Validar la unicidad del identificador del equipo.
- [ ] Endpoint de creación con estado inicial "Activo".

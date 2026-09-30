# HU-AD-05: Administrar equipos de cómputo

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Media |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | `HU-AD-04` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** consultar, editar y dar de baja equipos,  
**para** mantener el inventario actualizado cuando cambian, se reubican o se retiran computadoras.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra una lista de equipos con filtros por laboratorio y estado, y búsqueda por identificador.
- [ ] Se pueden editar los datos del equipo, incluido su cambio de laboratorio o ubicación.
- [ ] La baja es lógica: el equipo deja de poder registrarse pero conserva su historial de uso e incidencias.
- [ ] Un equipo dado de baja se puede reactivar.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Listado de equipos con filtros por laboratorio/estado y búsqueda por identificador.
- [ ] Edición de datos del equipo, incluido el cambio de laboratorio o ubicación.
- [ ] Endpoint de baja lógica y reactivación de equipos.

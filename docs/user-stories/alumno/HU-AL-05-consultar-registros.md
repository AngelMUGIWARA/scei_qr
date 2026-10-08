# HU-AL-05: Consultar mis registros de uso

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Media |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 2 |
| **Dependencias** | `HU-AL-03` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** consultar el historial de las computadoras que he utilizado,  
**para** saber cuándo y en qué equipos he trabajado.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra una lista ordenada del registro más reciente al más antiguo.
- [ ] Cada registro incluye equipo, laboratorio, fecha, hora de inicio y hora de fin.
- [ ] Solo se muestran los registros del alumno que inició sesión.
- [ ] Cuando no hay registros se muestra un mensaje informativo.
- [ ] La lista carga de forma progresiva cuando hay muchos registros.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoint de listado paginado de registros de uso por alumno.
- [ ] Implementar la pantalla de historial con carga progresiva.
- [ ] Manejar el estado vacío (sin registros).
- [ ] Pruebas de integración de la consulta filtrada por usuario.

# HU-AD-10: Consultar estadísticas y reportes del sistema

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Media |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | `HU-AD-08`, `HU-AD-09` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** ver estadísticas y reportes generales del sistema,  
**para** tener una visión global del uso de los equipos y de la atención de incidencias.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] El panel muestra el total de incidencias por estado y por laboratorio.
- [ ] Se muestra el tiempo promedio de resolución de incidencias.
- [ ] Se identifican los equipos con más incidencias y los más utilizados.
- [ ] Todas las estadísticas se pueden filtrar por periodo.
- [ ] Los datos provienen de la información generada en la aplicación móvil.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Endpoints de agregados: incidencias por estado/laboratorio y tiempo promedio de resolución.
- [ ] Cálculo de los equipos con más incidencias y más uso.
- [ ] Dashboard con filtros por periodo.

# HU-GEN-01: Control de acceso por rol

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Usuario del sistema |
| **Plataforma** | Móvil y Web |
| **Prioridad** | Alta |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 1 |
| **Dependencias** | Ninguna |

---

### Narrativa (Card)
**Como** usuario del sistema,  
**quiero** que cada rol solo pueda acceder a las funciones que le corresponden,  
**para** proteger la información y evitar acciones no autorizadas.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Los roles disponibles son Alumno, Soporte técnico y Administrador.
- [ ] Un alumno no puede ver ni ejecutar funciones de soporte técnico ni de administración.
- [ ] El soporte técnico solo puede gestionar incidencias, sin acceso a la gestión de equipos ni de personal.
- [ ] Las restricciones se validan en el servidor (API), no solo en la interfaz.
- [ ] Un intento de acceso no autorizado devuelve un mensaje claro y no expone datos.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Definir roles y permisos en el modelo de datos (Alumno, Soporte técnico, Administrador).
- [ ] Implementar middleware/guard de autorización en la API.
- [ ] Restringir rutas y pantallas según rol en la app móvil y en la web.
- [ ] Escribir pruebas de acceso no autorizado por endpoint.

---

> **Nota:** Historia técnica que aplica a todas las demás.

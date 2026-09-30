# HU-AL-03: Registrar el uso de un equipo

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 2 |
| **Dependencias** | `HU-AL-01`, `HU-AL-02`, `HU-AD-06` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** que al escanear el QR se registre automáticamente el equipo que utilizo junto con mis datos de usuario,  
**para** dejar constancia de su uso sin llenar formularios.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Después del escaneo se pide confirmar antes de guardar el registro.
- [ ] El registro guarda equipo, alumno, fecha y hora de inicio, hora fin,  profesor cuatrimestre y grupo.
- [ ] No se permite un segundo registro activo para el mismo alumno ni para un equipo que ya está en uso.
- [ ] Se muestra una confirmación visual cuando el registro se guardó correctamente.
- [ ] Si no hay conexión, se informa al alumno y se le permite reintentar sin volver a escanear.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Implementar pantalla de confirmación tras el escaneo.
- [ ] Crear endpoint para registrar el uso (equipo, alumno, fecha/hora de inicio).
- [ ] Validar que no exista un registro activo duplicado para el alumno o el equipo.
- [ ] Manejar el registro sin conexión y su reintento de envío.
- [ ] Pruebas de integración del flujo escaneo → registro.

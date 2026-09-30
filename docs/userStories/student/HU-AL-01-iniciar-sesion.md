# HU-AL-01: Iniciar sesión

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 1 |
| **Dependencias** | Ninguna |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** iniciar sesión en la aplicación móvil con mis credenciales,  
**para** acceder de forma segura y que mis registros queden asociados a mi usuario.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra un formulario con correo institucional(o matrícula) y contraseña.
- [ ] Con credenciales válidas se accede a la pantalla principal del alumno.
- [ ] Con credenciales incorrectas se muestra un mensaje de error sin indicar cuál dato falló.
- [ ] Los campos vacíos se validan antes de enviar la solicitud.
- [ ] La sesión se conserva hasta que el alumno la cierre o expire.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Implementar formulario de login en la app móvil.
- [ ] Consumir el endpoint de autenticación (JWT u otro mecanismo de sesión).
- [ ] Manejar errores de credenciales inválidas y campos vacíos.
- [ ] Persistir la sesión localmente en almacenamiento seguro.
- [ ] Pruebas unitarias y de UI del flujo de login.

# HU-AD-01: Iniciar sesión en la aplicación web

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 1 |
| **Dependencias** | Ninguna |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** iniciar sesión en la aplicación movil con mis credenciales,  
**para** acceder a las funciones de gestión y supervisión del sistema.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra un formulario con usuario y contraseña.
- [ ] Solo las cuentas con rol Administrador acceden al panel web.
- [ ] Con credenciales incorrectas se muestra un mensaje de error.
- [ ] Al ingresar se muestra el panel principal con el menú de gestión.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Implementar el formulario de login.
- [ ] Restringir el acceso solo a cuentas con rol Administrador.
- [ ] Manejar errores de autenticación.

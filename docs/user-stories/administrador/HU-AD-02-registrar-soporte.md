# HU-AD-02: Registrar personal de soporte técnico

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
**quiero** dar de alta a los técnicos de soporte,  
**para** que puedan iniciar sesión en la aplicación móvil y atender incidencias.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] El formulario solicita nombre completo, correo, usuario y contraseña inicial.
- [ ] El correo y el usuario deben ser únicos; si ya existen se muestra un error.
- [ ] Al guardar, la cuenta queda activa con rol Soporte técnico.
- [ ] El técnico registrado puede iniciar sesión en la aplicación móvil.
- [ ] Se muestra una confirmación de que el registro fue exitoso.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Formulario de alta de técnico (nombre, correo, usuario, contraseña inicial).
- [ ] Validar la unicidad de correo y usuario.
- [ ] Endpoint de creación de cuenta con rol Soporte técnico.
- [ ] Mostrar confirmación visual del alta exitosa.

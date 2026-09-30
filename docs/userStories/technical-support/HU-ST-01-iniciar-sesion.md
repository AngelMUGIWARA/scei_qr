# HU-ST-01: Iniciar sesión

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Técnico de soporte |
| **Plataforma** | Móvil |
| **Prioridad** | Alta |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 1 |
| **Dependencias** | `HU-AD-02` |

---

### Narrativa (Card)
**Como** técnico de soporte,  
**quiero** iniciar sesión en la aplicación móvil con la cuenta que me asignó el administrador,  
**para** acceder a las incidencias desde cualquier laboratorio.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra un formulario con usuario y contraseña.
- [ ] Solo pueden ingresar las cuentas de soporte técnico activas.
- [ ] Con credenciales incorrectas o cuenta desactivada se muestra un mensaje de error.
- [ ] Al ingresar se muestra la pantalla principal de soporte con las incidencias.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Adaptar el flujo de login para cuentas con rol Soporte técnico.
- [ ] Validar que solo cuentas activas puedan autenticarse.
- [ ] Pruebas de intento de acceso con una cuenta desactivada.

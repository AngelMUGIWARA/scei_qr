# HU-AD-03: Administrar personal de soporte técnico

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
| **Prioridad** | Media |
| **Origen** | Documento |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | `HU-AD-02` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** consultar, editar y desactivar cuentas de técnicos de soporte,  
**para** mantener actualizado el personal sin perder el historial de atención.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Se muestra una lista de técnicos con búsqueda por nombre.
- [ ] Se pueden editar los datos de contacto y restablecer la contraseña.
- [ ] Al desactivar una cuenta, el técnico ya no puede iniciar sesión pero se conservan sus incidencias atendidas.
- [ ] Una cuenta desactivada se puede reactivar.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Listado de técnicos con búsqueda por nombre.
- [ ] Edición de datos de contacto y reseteo de contraseña.
- [ ] Endpoint de activar/desactivar cuenta (baja lógica).
- [ ] Conservar el historial de incidencias atendidas al desactivar una cuenta.

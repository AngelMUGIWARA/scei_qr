# HU-GEN-02: Cerrar sesión

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Usuario del sistema |
| **Plataforma** | Móvil y Web |
| **Prioridad** | Media |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 4 |
| **Dependencias** | Ninguna |

---

### Narrativa (Card)
**Como** usuario del sistema,  
**quiero** cerrar mi sesión desde la aplicación,  
**para** evitar que otra persona use mi cuenta en un dispositivo compartido.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Existe una opción visible de "Cerrar sesión" en la aplicación móvil y en la web.
- [ ] Al cerrar sesión se elimina el token o sesión almacenada en el dispositivo.
- [ ] Después de cerrar sesión no se puede volver a las pantallas internas con el botón "atrás".
- [ ] La sesión también expira automáticamente tras un periodo de inactividad definido por el equipo.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Implementar endpoint/acción de logout que invalide el token de sesión.
- [ ] Eliminar el token almacenado localmente (móvil y web).
- [ ] Configurar expiración automática de sesión por inactividad.
- [ ] Pruebas de que las rutas protegidas dejan de ser accesibles tras cerrar sesión.

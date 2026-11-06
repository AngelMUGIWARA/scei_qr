# HU-AD-12: Gestionar cuentas de alumnos

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Móvil |
| **Prioridad** | Media |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 2 |
| **Dependencias** | `HU-AD-01` |

---

### Narrativa (Card)
**Como** administrador,  
**quiero** registrar o importar las cuentas de los alumnos,  
**para** que puedan iniciar sesión y sus registros de uso queden asociados a ellos.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [x] Se define cómo se dan de alta los alumnos (captura individual, carga masiva o integración con el sistema escolar).
  - *Acordado con el equipo: **captura individual** (`definicionAltaAlumno`). Carga masiva e integración escolar quedan fuera de alcance hasta que se planifiquen.*
- [x] Cada alumno tiene al menos nombre, matrícula y credenciales de acceso.
  - *Validado en dominio (`SolicitudAltaAlumno.errores`) y por el backend (`CreateUsuarioRequest`); credencial = correo institucional.*
- [x] Se puede desactivar una cuenta conservando su historial.
  - *Baja lógica vía `PATCH /usuarios/:id {activo:false}`; la cuenta sigue visible en el listado y el backend nunca borra el registro.*

---

### Tareas de Ingeniería (Engineering Tasks)
- [x] Definir con el equipo el mecanismo de alta de alumnos (captura, carga masiva o integración escolar).
  - *Decisión: captura individual en `RegistrarAlumnoScreen`.*
- [x] Modelar los datos del alumno (nombre, matrícula, credenciales).
  - *`lib/dominio/alumno.dart` + `lib/dominio/alta_alumno.dart`.*
- [x] Endpoint de baja lógica conservando el historial de uso.
  - *Ya existente en el backend (`PATCH /usuarios/:id`); no requirió cambios en `scei_qr_api`.*
- [x] Pantalla de gestión (listado con búsqueda, alta, baja lógica y reactivación) + feature `lib/features/alumnos/`.
- [ ] Nota: refinar esta historia con el equipo antes de desarrollarla; aún no cumple la Definition of Ready.
  - *Realizado: mecanismo de alta acordado (captura individual) antes de implementar.*

---

> **Nota (actualizada):** El equipo acordó **captura individual** como mecanismo de alta para la iteración 2; la carga masiva y la integración con el sistema escolar quedan fuera de alcance. El backend no expone `fechaBaja` (solo `activo` y `createdAt`): si se necesita mostrar la fecha de alta/baja de la cuenta, debe coordinarse como mejora en `scei_qr_api`.

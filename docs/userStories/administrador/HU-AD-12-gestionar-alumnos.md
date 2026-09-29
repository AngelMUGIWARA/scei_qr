# HU-AD-12: Gestionar cuentas de alumnos

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Administrador |
| **Plataforma** | Web |
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
- [ ] Se define cómo se dan de alta los alumnos (correo institucional).
- [ ] Cada alumno tiene al menos nombre, matrícula y credenciales de acceso.
- [ ] Se puede desactivar una cuenta conservando su historial.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Definir con el equipo el mecanismo de alta de alumnos (captura, carga masiva o integración escolar).
- [ ] Modelar los datos del alumno (nombre, matrícula, credenciales).
- [ ] Endpoint de baja lógica conservando el historial de uso.
- [ ] Nota: refinar esta historia con el equipo antes de desarrollarla; aún no cumple la Definition of Ready.

---

> **Nota:** Pendiente de refinamiento: el documento no especifica quién crea las cuentas de alumno. No cumple la Definition of Ready hasta que el equipo lo defina.

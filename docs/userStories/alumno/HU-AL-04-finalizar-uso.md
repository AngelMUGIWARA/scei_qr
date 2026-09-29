# HU-AL-04: Finalizar el uso de un equipo

| Metadato | Detalle |
| :--- | :--- |
| **Rol** | Alumno |
| **Plataforma** | Móvil |
| **Prioridad** | Media |
| **Origen** | Propuesta |
| **Iteración sugerida** | Iteración 2 |
| **Dependencias** | `HU-AL-03` |

---

### Narrativa (Card)
**Como** alumno,  
**quiero** indicar cuándo termino de usar una computadora,  
**para** que quede registrado el tiempo de uso y el equipo aparezca como disponible.

---

### Criterios de Aceptación (Confirmation / Pruebas)
- [ ] Mientras exista un registro activo se muestra el botón "Finalizar uso".
- [ ] Al finalizar se guarda la fecha y hora de fin y se calcula la duración.
- [ ] Una vez finalizado, el equipo puede ser registrado por otro alumno.
- [ ] Se muestra un resumen del uso (equipo, hora de inicio, hora de fin y duración).

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Implementar el botón "Finalizar uso" condicionado a un registro activo.
- [ ] Endpoint para actualizar el registro con hora de fin y cálculo de duración.
- [ ] Liberar el equipo para nuevos registros al finalizar el uso.
- [ ] Mostrar un resumen del uso al finalizar.
- [ ] Definir con el equipo si se implementa un cierre automático por tiempo máximo.

---

> **Nota:** El equipo debe definir si el sistema cerrará automáticamente los registros que el alumno olvide finalizar (por ejemplo, tras un tiempo máximo).

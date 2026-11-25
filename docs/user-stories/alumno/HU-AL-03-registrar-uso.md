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
- [ ] El registro guarda equipo, alumno, fecha y hora de inicio.
- [ ] No se permite un segundo registro activo para el mismo alumno ni para un equipo que ya está en uso.
- [ ] Se muestra una confirmación visual cuando el registro se guardó correctamente.
- [x] Si no hay conexión, se informa al alumno y se le permite reintentar sin volver a escanear.

---

### Tareas de Ingeniería (Engineering Tasks)
- [ ] Implementar pantalla de confirmación tras el escaneo.
- [ ] Crear endpoint para registrar el uso (equipo, alumno, fecha/hora de inicio).
- [ ] Validar que no exista un registro activo duplicado para el alumno o el equipo.
- [x] Manejar el registro sin conexión y su reintento de envío.
- [x] Pruebas de integración del flujo escaneo → registro.

---

### Notas de implementación (offline y reintentos)

- El registro se intenta de inmediato contra `POST /usos`. Si falla por falta de
  conexión (`NetworkException`), se guarda en una cola local persistente
  (`SharedPreferences`) con una **clave de idempotencia** estable.
- La pantalla muestra el estado **"Uso pendiente de sincronizar"**; el registro
  se reenvía automáticamente al recuperar la conexión (`connectivity_plus`) y al
  arrancar la app.
- Los errores no recuperables (409, 404, 403, 422) no se encolan y se muestran
  al alumno. Los errores 5xx se conservan en la cola y se incrementa el número
  de intentos.
- Pruebas: `test/registrar_uso_provider_test.dart`, `test/confirmar_uso_screen_test.dart`,
  `test/cola_usos_pendientes_repository_test.dart`,
  `test/sincronizar_usos_pendientes_usecase_test.dart` y
  `test/registro_uso_integration_test.dart`.

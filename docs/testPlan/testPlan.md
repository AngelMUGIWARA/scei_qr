# Esquema de pruebas

### Sistema móvil y web para el control de uso e incidencias de equipos de cómputo mediante códigos QR

---

## 1. Alcance del esquema

Este esquema define cómo se va a comprobar, mediante pruebas, que cada historia de usuario del backlog cumple con lo que promete. El backlog actual contiene **30 historias** (se eliminaron `HU-AL-04 Finalizar el uso de un equipo` y `HU-ST-09 Escanear el QR del equipo en sitio`; las historias de Alumno posteriores a la eliminada se renumeraron). De estas 30, el esquema cubre **26**, clasificadas en tres tipos de prueba:

- **Interfaz:** verifica lo que el usuario ve y hace en la pantalla (validaciones visibles, mensajes, navegación, estados vacíos).
- **Unitaria:** verifica una pieza de lógica aislada (cálculos, reglas de negocio, algoritmos), sin depender de la interfaz ni de servicios externos.
- **Integración:** verifica el flujo completo de una funcionalidad, atravesando frontend, backend y base de datos.

Las 4 historias restantes de las 30 no encajan de forma confiable en ninguno de estos tres tipos por razones distintas (dependencia de servicios externos, verificación física/manual, o falta de definición). Se documentan por separado en la sección 3, junto con la razón de su exclusión.

El criterio de aprobación de cada historia se basa en sus criterios de aceptación ya definidos en el backlog; aquí se resume en una sola condición verificable.

---

## 2. Esquema de pruebas

| Historia de usuario | Qué comprueba | Tipo | Criterio de aprobación |
|---|---|---|---|
| HU-GEN-01 Control de acceso por rol | Que cada rol solo pueda ejecutar las funciones que le corresponden, validado en el servidor | Integración | Un usuario autenticado con un rol no puede acceder a endpoints ni pantallas de otro rol; el intento devuelve un error controlado |
| HU-GEN-02 Cerrar sesión | Que al cerrar sesión se invalide el token y se bloquee el acceso a rutas protegidas | Integración | Tras cerrar sesión, cualquier solicitud a una ruta protegida es rechazada |
| HU-AL-01 Iniciar sesión | Que el alumno pueda autenticarse con credenciales válidas y sea rechazado con inválidas | Integración | Con credenciales correctas se recibe una sesión activa; con incorrectas, un mensaje de error sin acceso |
| HU-AL-02 Escanear el código QR de una computadora | Que la cámara lea el QR y la app responda según si el equipo es válido, inválido o está de baja | Interfaz | Cada uno de los tres escenarios (válido, inválido, de baja) muestra el mensaje o pantalla correcta |
| HU-AL-03 Registrar el uso de un equipo | Que el registro se cree correctamente y no se dupliquen registros activos | Integración | Un registro válido se guarda con los datos correctos; un intento duplicado (mismo alumno o mismo equipo) es rechazado |
| HU-AL-04 Consultar mis registros de uso | Que el alumno vea únicamente su propio historial, ordenado y con manejo de lista vacía | Interfaz | La lista muestra solo registros del alumno en sesión, ordenados del más reciente al más antiguo, con mensaje si está vacía |
| HU-AL-05 Reportar una incidencia de un equipo | Que el reporte se cree con folio, estado inicial y datos completos | Integración | Al enviar un reporte válido se crea la incidencia en estado "Pendiente" con folio asignado; con campos faltantes, el envío se bloquea |
| HU-AL-06 Consultar el estado de mis reportes | Que el alumno vea el estado real de sus reportes y su historial de cambios | Interfaz | El estado mostrado en la app coincide con el registrado por soporte técnico en el backend |
| HU-AL-07 Adjuntar una foto al reporte | Que la imagen se valide, se suba y quede visible en el detalle de la incidencia | Integración | Una imagen válida se adjunta y es visible para alumno, soporte y administrador; una inválida (formato/tamaño) es rechazada |
| HU-ST-01 Iniciar sesión (soporte técnico) | Que solo cuentas de soporte técnico activas puedan autenticarse | Integración | Una cuenta activa inicia sesión correctamente; una desactivada es rechazada |
| HU-ST-02 Consultar las incidencias reportadas | Que la lista de incidencias se muestre ordenada y se pueda filtrar | Interfaz | Al aplicar un filtro (estado, laboratorio, fecha) la lista mostrada corresponde exactamente al filtro aplicado |
| HU-ST-03 Identificar la computadora y su ubicación | Que el detalle de una incidencia muestre los datos correctos del equipo y su ubicación | Interfaz | El detalle mostrado coincide con los datos reales del equipo asociado a la incidencia |
| HU-ST-04 Tomar una incidencia para su atención | Que una incidencia solo pueda ser tomada por un técnico a la vez | Integración | Si dos técnicos intentan tomar la misma incidencia al mismo tiempo, solo uno la obtiene y el otro recibe un aviso |
| HU-ST-05 Actualizar el estado de una incidencia | Que solo se permitan las transiciones de estado válidas y por el técnico asignado | Unitaria | Las transiciones permitidas (Pendiente→En atención→Resuelta) se aceptan; cualquier otra transición o un técnico no asignado son rechazados |
| HU-ST-06 Registrar la solución aplicada | Que no se pueda cerrar una incidencia sin solución registrada | Integración | Un intento de marcar "Resuelta" sin texto de solución es rechazado; con solución, la incidencia cambia de estado y queda visible para alumno y administrador |
| HU-ST-07 Consultar el historial de incidencias atendidas | Que el técnico vea solo las incidencias que él resolvió, con filtros funcionales | Interfaz | La lista mostrada corresponde únicamente a incidencias resueltas por el técnico en sesión |
| HU-AD-01 Iniciar sesión en la aplicación web | Que solo cuentas con rol Administrador puedan acceder al panel web | Integración | Una cuenta de Administrador accede al panel; una cuenta de otro rol es rechazada |
| HU-AD-02 Registrar personal de soporte técnico | Que no se puedan crear cuentas duplicadas y la cuenta creada pueda iniciar sesión en la app móvil | Integración | Un alta con correo/usuario ya existente es rechazada; un alta válida permite iniciar sesión con esa cuenta desde la app móvil |
| HU-AD-03 Administrar personal de soporte técnico | Que desactivar una cuenta le impida iniciar sesión sin borrar su historial | Interfaz | Una cuenta desactivada no puede iniciar sesión, pero sus incidencias atendidas siguen visibles en el historial |
| HU-AD-04 Registrar equipos de cómputo | Que no se puedan registrar equipos con identificador duplicado | Integración | Un alta con identificador ya existente es rechazada; un alta válida queda con estado "Activo" |
| HU-AD-05 Administrar equipos de cómputo | Que la baja de un equipo sea lógica y conserve su historial | Interfaz | Un equipo dado de baja no puede ser escaneado para nuevos registros, pero su historial de uso e incidencias permanece visible |
| HU-AD-06 Generar el código QR único de cada equipo | Que cada equipo tenga un QR único y que la regeneración invalide el anterior | Unitaria | No existen dos equipos con el mismo código QR; al regenerar el QR de un equipo, el código anterior deja de ser válido |
| HU-AD-08 Consultar el historial de uso de los equipos | Que la tabla de historial coincida con los registros generados desde la app móvil | Interfaz | Los datos mostrados en la tabla web coinciden exactamente con los registros creados desde la aplicación móvil |
| HU-AD-09 Consultar y supervisar las incidencias | Que la vista de supervisión filtre correctamente y resalte incidencias con más tiempo pendiente | Interfaz | Al aplicar un filtro, solo se muestran las incidencias que lo cumplen; las de mayor tiempo pendiente aparecen resaltadas |
| HU-AD-10 Consultar estadísticas y reportes del sistema | Que los cálculos de estadísticas (promedios, conteos) sean correctos | Unitaria | Los valores calculados (tiempo promedio de resolución, conteos por estado/laboratorio) coinciden con el resultado esperado sobre un conjunto de datos de prueba |
| HU-AD-11 Exportar reportes | Que el archivo exportado contenga los datos filtrados y los metadatos de exportación | Integración | El archivo exportado (PDF/CSV) contiene exactamente los registros filtrados en pantalla, más los filtros aplicados y la fecha de generación |

---

## 3. Qué queda fuera

Estas 4 historias no se incluyen en el esquema de pruebas de interfaz, unitarias o de integración, por las siguientes razones:

**HU-AL-08 — Recibir notificación de cambio de estado**
Depende de un servicio externo de notificaciones push (FCM/APNs) y del estado del dispositivo del usuario (permisos, conectividad, app en segundo plano). No se puede verificar de forma confiable ni automatizada dentro de pruebas unitarias, de interfaz o de integración controladas por el equipo; requiere verificación manual/exploratoria en dispositivos reales.

**HU-ST-08 — Recibir notificación de nuevas incidencias**
Misma razón que HU-AL-08: depende del servicio externo de notificaciones push y de condiciones del dispositivo que están fuera del control del equipo de desarrollo. Se valida de forma manual/exploratoria, no dentro de este esquema.

**HU-AD-07 — Descargar e imprimir los códigos QR**
El resultado final (una etiqueta física legible por la cámara del teléfono) depende de la calidad de impresión, el papel y el tamaño elegido por quien la imprime, factores que no se pueden comprobar con una prueba automatizada. Se valida mediante inspección visual manual de la etiqueta impresa.

**HU-AD-12 — Gestionar cuentas de alumnos**
Todavía no cumple la Definition of Ready: el documento del proyecto no especifica quién ni cómo se dan de alta las cuentas de alumno (captura individual, carga masiva o integración con el sistema escolar). No se puede diseñar un criterio de aprobación confiable para una historia cuyo comportamiento esperado aún no está definido; debe refinarse con el equipo antes de poder planear sus pruebas.
# 🎨 PROMPT MAESTRO — Prototipos en Google Stitch

**Proyecto:** `scei_qr` — Sistema móvil de control de uso e incidencias de equipos de cómputo mediante códigos QR
**Plataforma base:** Flutter (Android / iOS / Web)
**Backlog:** `docs/user-stories/` (32 historias, metodología XP)
**Fecha:** 2026-10-19

---

## 📌 Cómo usar este documento

1. **Bloque 1 a 8** = *contexto fijo*. Se copian **una sola vez** al inicio de la conversación con Stitch (o se pegan en la sección de "contexto del proyecto" si Stitch lo permite).
2. **Bloque 9** = *plantilla maestra de pantalla*. Se copia **por cada pantalla** que quieras prototipar, reemplazando los campos entre `[CORCHETES]`.
3. **Bloque 10** = *catálogo de pantallas*. Elige el ID de la historia y genera.
4. **Bloque 11** = *checklist de aceptación*. Úsalo antes de dar por bueno un prototipo.

> **Regla de oro:** *un prompt = una pantalla*. Stitch rinde mucho mejor cuando pides una pantalla concreta que cuando le pides "toda la app".

---

# PARTE A — CONTEXTO FIJO (pegar una vez)

## 1. Rol que asume Stitch

```
Eres UI/UX Designer senior especializado en productos móviles de tipo
"field service / asset management". Diseñas el prototipo navegable de una
app Flutter llamada "SCEI QR" para un instituto tecnológico.

Tu entregable por cada pantalla: (a) mockup visual fiel y (b) código
HTML/CSS responsive autocontenido (Tailwind CSS o CSS puro) que pueda
traducirse después a widgets Flutter con Material 3.

Hablas y etiquetas TODO en español neutro (México). No mezclas inglés en la
UI; el inglés solo se acepta en clases CSS/variables técnicas.
```

## 2. Descripción del producto

```
SCEI QR es una app móvil para controlar el uso y las incidencias de las
computadoras de los laboratorios del instituto.

- Cada computadora tiene un código QR único pegado en ella.
- El ALUMNO escanea el QR, registra su uso y puede reportar fallas.
- EL TÉCNICO DE SOPORTE atiende las incidencias reportadas.
- EL ADMINISTRADOR gestiona inventario de equipos, personal de soporte,
  genera/descarga los QR y consulta estadísticas.
- No existe backend real aún: el prototipo usa datos de ejemplo (mock).
- Seis pantallas de arranque (login) comparten el mismo diseño; solo cambia
  el home al que se redirige según el rol.
```

## 3. Roles y navegación por rol (HU-GEN-01, HU-GEN-02)

| Rol | Home | Navegación inferior / lateral | Acciones principales |
|---|---|---|---|
| **Alumno** | `alumno_home` | 📷 Escanear · 📋 Mis registros · 🛠️ Mis reportes · ⚙️ Perfil | Escanear QR, registrar/finalizar uso, reportar incidencia, ver folios |
| **Soporte técnico** | `soporte_home` | 🛠️ Incidencias · 🕒 Historial · 📷 Escanear (en sitio) · ⚙️ Perfil | Filtrar, tomar incidencia, cambiar estado, registrar solución |
| **Administrador** | `admin_home` | 🖥️ Equipos · 🛠️ Incidencias · 📊 Reportes · 👥 Personal · ⚙️ Más | CRUD equipos/soporte, generar QR, historiales, estadísticas |

**Restricciones de rol (deben reflejarse en la UI, no solo en el backend):**
- El alumno **nunca** ve menús de incidencias globales, equipos ni personal.
- El soporte técnico **nunca** ve gestión de equipos ni de personal.
- El administrador **no** escanea para usar equipos (solo genera/administra QR).
- "Cerrar sesión" siempre visible en el AppBar/menú de perfil (HU-GEN-02).

## 4. Estados de una incidencia (catálogo cerrado)

| Estado | Chip/color sugerido | Quién lo genera |
|---|---|---|
| **Pendiente** | Ámbar `#F59E0B` | Alumno, al reportar |
| **En atención** | Azul `#3B82F6` | Soporte técnico, al tomarla |
| **Resuelta** | Verde `#10B981` | Soporte técnico, al registrar solución |

Estados adicionales en equipo: **Activo** (verde) / **Dado de baja** (gris roto).
Estados de red: **cargando**, **vacío**, **error**, **sin conexión**, **éxito**.

## 5. Sistema de diseño (Design tokens)

```
Sistema de diseño: MATERIAL 3 (Material You), tono medio, sin bordes
excesivamente redondeados, look institucional y sobrio (no es una app de
entretenimiento).
```

### 5.1 Color

| Token | Valor | Uso |
|---|---|---|
| `primary` | `#1D4ED8` (azul 700) | Botones principales, AppBar, links |
| `primary-container` | `#DBEAFE` | Chips seleccionados, fondos suaves |
| `secondary` | `#0F766E` (teal 700) | Acentos, íconos de éxito secundario |
| `surface` | `#FFFFFF` | Tarjetas, hojas |
| `surface-variant` | `#F5F7FA` | Fondo de pantalla (no blanco puro) |
| `outline` | `#E2E8F0` | Bordes de campos y separadores |
| `text-primary` | `#0F172A` | Texto principal (contraste AA) |
| `text-secondary` | `#64748B` | Textos de apoyo, placeholders |
| `error` | `#DC2626` | Errores de validación, estados destructivos |
| `success` | `#10B981` | Confirmaciones, "Resuelta" |
| `warning` | `#F59E0B` | "Pendiente", advertencias |

> Si el instituto tiene colores institucionales, reemplaza `primary`/`secondary`
> y conserva el resto de la escala. **Mantén contraste mínimo AA (4.5:1).**

### 5.2 Tipografía

```
Familia: Roboto (Flutter/Material por defecto) — sin fuentes decorativas.
Escala (sp): Display 32/40 · H1 28/36 · H2 22/28 · Title 18/24 ·
Body 16/24 · Body-small 14/20 · Label 12/16 (medias: 400/500/700).
Solo 3 tamaños visibles por pantalla: título, subtítulo/cuerpo, label.
```

### 5.3 Espaciado, radios y elevación

```
Rejilla de 8 dp: 4 · 8 · 16 · 24 · 32 (margen de pantalla = 16 dp).
Radio: campos 12 dp · tarjetas 16 dp · botones 24 dp (pill) · sheets 24 dp arriba.
Elevación: sombra sutil solo en tarjetas y FAB (0 1 3 rgba(15,23,42,.08));
en listas usar divisores, no sombras.
Área táctil mínima: 48 × 48 dp para CUALQUIER control interactivo.
```

### 5.4 Componentes reutilizables (definirlos una vez y reusarlos)

```
[ ] AppBar con título + acción (atrás en pantallas de detalle)
[ ] Bottom Navigation Bar (3-4 destinos) / Navigation Rail en tablet
[ ] FAB principal (solo alumno: "Escanear"; solo soporte: acción contextual)
[ ] Card de incidencia: folio + chip de estado + equipo + laboratorio + fecha
[ ] Card de equipo: identificador + laboratorio + ubicación + estado
[ ] Chip de estado (colores del catálogo) y chip de filtro seleccionable
[ ] Botón primario (pill,alto 48), botón secundario (outlined), botón texto
[ ] Campo de texto con label flotante + mensaje de error inline
[ ] Selector (dropdown / bottom sheet) para tipo de problema y filtros
[ ] Lista de registros con fecha/hora y duración
[ ] Sección de detalle con filas etiqueta/valor
[ ] Empty state (ícono + título + frase + acción)
[ ] Skeleton/loading (3-5 placeholders pulsantes) y spinner
[ ] Snackbar de éxito (verde) y de error (rojo) con acción "Reintentar"
[ ] Diálogo de confirmación (Cerrar sesión, Finalizar uso, Dar de baja)
[ ] Bottom sheet de filtros
[ ] Scanner QR: viewport fullscreen con marco, botón linterna y "ingresar código manual"
[ ] Tarjeta de usuario en el AppBar (nombre completo + rol)
```

## 6. Patrón de diseño a seguir

```
PATRÓN DE UI: Atomic / Component-based design sobre Material 3.
- Nivel 1 (tokens): colores, tipografía, espaciado, radios → los de la sección 5.
- Nivel 2 (componentes): los 18 elementos de la sección 5.4.
- Nivel 3 (patrones de pantalla): se reensamblan componentes, nunca se inventan
  elementos nuevos por pantalla.
- Nivel 4 (flujo): ruteo por rol + navegación por pila (detalle siempre con "atrás").

PATRÓN DE INTERACCIÓN POR TIPO DE PANTALLA:
1. Autenticación    → formulario centrado, 1 columna, CTA fijo abajo.
2. Escaneo          → fullscreen inmersivo, sin AppBar, feedback inmediato.
3. Lista + filtros  → master list con búsqueda, chips de filtro y pull-to-refresh.
4. Detalle          → list-detail con secciones etiqueta/valor y CTA inferior.
5. Formulario       → 1 columna, validación inline al salir del campo,
                      CTA "Guardar" fijo en la zona del pulgar.
6. Confirmación     → éxito con folio + CTA "Ver seguimiento" / "Escanear otro".
7. Dashboard        → KPI cards 2×2 en móvil, grid 4 columnas en tablet/desktop,
                      gráficas simples (barras/donut) con leyenda.
8. Estados          → TODA pantalla de lista/formulario debe existir en 5 versiones:
                      carga (skeleton), datos, vacío, error y sin conexión.
```

**Patrones de arquitectura que el prototipo debe reflejar** (para que la traducción a Flutter sea directa):

```
- Clean Architecture ligera por features: features/auth, features/qr,
  features/incidencias, features/equipos, features/reportes.
- Estados de UI explícitos: initial · loading · success · empty · error.
- Feedback optimista solo para acciones reversibles; las irreversibles
  (Dar de baja, Cerrar incidencia) piden confirmación explícita.
- Errores de autenticación SIEMPRE genéricos: "Usuario o contraseña incorrectos"
  (nunca decir cuál campo falló).
```

## 7. Reglas responsive (obligatorias)

```
El prototipo debe verse bien en 3 breakpoints. Pide SIEMPRE el código con
estas reglas aplicadas:

BREAKPOINTS
- Móvil  (base)      : 320–599 px  → 1 columna, Bottom Nav, FAB, márgenes 16 px
- Tablet             : 600–1023 px → 2 columnas (lista | detalle), Navigation Rail,
                                     grids de tarjetas en 2–3 columnas,
                                     máximo de ancho de contenido 900 px centrado
- Desktop / Web      : ≥ 1024 px   → Navigation Drawer o Rail expandido,
                                     grids de tarjetas en 3–4 columnas,
                                     máximo de ancho de contenido 1200 px centrado

REGLAS
1. Usar contenedores con max-width + margin-inline: auto (nunca estirar
   formularios a 100% del viewport en pantallas grandes).
2. Los formularios nunca pasan de 640 px de ancho aunque la pantalla sea mayor.
3. Listas densas en tablet: cambiar a tabla/filas extendidas, no apilar tarjetas.
4. Soportar orientación vertical y horizontal sin cortar texto ni CTAs.
5. Textos fluidos: escalar con clamp() y permitir wrap; prohibido overflow.
6. Insets seguros: safe-area superior (notch) e inferior (barra de gestos).
7. Zona del pulgar: CTA principal siempre en la mitad inferior en móvil.
8. Touch targets ≥ 48 px; separación ≥ 8 px entre objetivos adyacentes.
9. Alto de fila de lista: 64–72 px; nunca menos de 56 px.
10. Navegación: Bottom Nav (móvil) → Rail (tablet) → Drawer (desktop).
11. Contraste AA: texto 4.5:1, iconos/contornos grandes 3:1.
12. Todo control debe tener 4 estados visibles: default, hover (web),
    pressed y disabled.
```

## 8. Datos de ejemplo (mock) — usar siempre los mismos

```
USUARIOS
- alumno01 / alumno123   → "Ana López Martínez", rol Alumno, grupo 3A-MAT
- soporte01 / soporte123 → "Carlos Ramírez Díaz", rol Soporte técnico
- admin01 / admin123     → "María Fernanda Soto", rol Administrador

LABORATORIOS: Lab. A, Lab. B, Lab. C (Edificio 2, pisos 1 y 2)
EQUIPOS: PC-A01 … PC-A15 (Lab. A), PC-B01 … PC-B12 (Lab. B), PC-C01 … PC-C10 (Lab. C)
         campos: identificador, laboratorio, ubicación ("Mesa 3, ventana"),
         descripción ("Dell OptiPlex 3080"), estado (Activo/Baja)
INCIDENCIAS: folios INC-2026-0001 … INC-2026-0042
         tipos: Hardware · Software · Red · Periféricos · Otro
         ejemplos: "No enciende", "No tiene conexión a red",
                   "Teclado no responde", "Sistema operativo lento"
REGISTROS DE USO: fecha/hora inicio, fin y duración (hh:mm) por alumno/equipo
FECHAS: formato dd/mm/yyyy · hora 24 h (14:35)
NÚMEROS: separador de miles con coma, decimales con punto
```

---

# PARTE B — PLANTILLA MAESTRA DE PANTALLA (pegar por cada pantalla)

> Copia el bloque completo y reemplaza los `[CORCHETES]`.

```text
PANTALLA: [NOMBRE DE LA PANTALLA]  |  ID: [HU-XX-NN]  |  Rol: [Alumno / Soporte técnico / Administrador]

OBJETIVO (historia de usuario)
Como [rol], quiero [funcionalidad], para [beneficio].

CONTENIDO OBLIGATORIO
1. [Elemento 1: qué debe aparecer, con qué datos de ejemplo]
2. [Elemento 2]
3. [Elemento 3]
4. Estados requeridos: carga (skeleton) · datos · vacío · error · sin conexión.

REGLAS DE LA PANTALLA
- Sistema de diseño: Material 3 con los tokens de la sección 5 (colores, tipografía
  Roboto, rejilla de 8 dp, radios 12/16/24, áreas táctiles 48 dp).
- Navegación: [Bottom Nav con destinos X / AppBar con "atrás" / fullscreen].
- CTA principal: "[texto del botón]" en la zona inferior (móvil).
- Validaciones (si aplica): [campo obligatorio / formato / unicidad] con error inline.
- Restricción de rol: [qué NO debe ver este rol en esta pantalla].
- Accesibilidad: contraste AA, etiquetas visibles (no solo placeholder),
  mensajes de error en texto + ícono, foco visible.

RESPONSIVE (obligatorio)
- Móvil 320–599 px: 1 columna, Bottom Nav, márgenes 16 px.
- Tablet 600–1023 px: 2 columnas (si aplica lista/detalle) o grid 2–3 columnas,
  Navigation Rail, contenido máx. 900 px centrado.
- Desktop ≥1024 px: grid 3–4 columnas, contenido máx. 1200 px centrado,
  formularios máx. 640 px.
- Sin overflow de texto en ningún breakpoint; soportar retrato y paisaje.

ENTREGABLE
1. Mockup visual fiel (mobile-first).
2. Código HTML/CSS responsive autocontenido (Tailwind o CSS puro) con los
   breakpoints anteriores, usando las clases/variables del sistema de diseño.
3. Lista de componentes reutilizables usados (de la sección 5.4).
4. Variantes: [solo si aplica] tablet y desktop.

DATOS MOCK
Usar exactamente los datos de la sección 8 (usuarios, laboratorios, equipos,
folios INC-2026-xxxx, fechas dd/mm/yyyy).

NO HACER
- No inventar pantallas, botones o estados fuera del rol.
- No usar imágenes de stock ni íconos inventados: íconos Material equivalentes.
- No añadir texto en inglés en la interfaz.
- No colorear elementos que no sean estados del catálogo (sección 4).
```

---

# PARTE C — CATÁLOGO DE PANTALLAS (32 historias → pantallas)

## Iteración 1 — Base, acceso e inventario

| Pantalla ID | HU | Notas de diseño |
|---|---|---|
| `splash` | HU-GEN-01 | Logo + indicador; restaura sesión |
| `login` | HU-AL-01 / HU-ST-01 / HU-AD-01 | Formulario único, error genérico, "recordarme" |
| `recuperar-password` | — | Opcional, misma shell de login |
| `alumno_home` | HU-GEN-01 | Home placeholder + menú de perfil + cerrar sesión |
| `soporte_home` | HU-GEN-01 | Ídem, destinos de soporte |
| `admin_home` | HU-GEN-01 | Ídem, destinos de administrador |
| `admin_registrar_soporte` | HU-AD-02 | Formulario de alta de técnico |
| `admin_lista_soporte` | HU-AD-03 | Lista + editar/activar/desactivar |
| `admin_registrar_equipo` | HU-AD-04 | Formulario (identificador único, lab, ubicación, marca) |
| `admin_lista_equipos` | HU-AD-05 | Lista con filtros + estados Activo/Baja |
| `admin_generar_qr` | HU-AD-06 | Vista previa del QR + datos del equipo |
| `admin_descargar_qr` | HU-AD-07 | Cards de QR con descargar/imprimir/compartir |

## Iteración 2 — Flujo del alumno

| Pantalla ID | HU | Notas de diseño |
|---|---|---|
| `alumno_escanear_qr` | HU-AL-02 | Fullscreen cámara, marco, linterna, código manual, permisos denegados |
| `alumno_confirmar_equipo` | HU-AL-02/03 | Equipo identificado → confirmar registro de uso |
| `alumno_uso_activo` | HU-AL-03/04 | Timer de uso en curso + "Finalizar uso" |
| `alumno_mis_registros` | HU-AL-05 | Lista con inicio/fin/duración + filtros por fecha |
| `admin_gestionar_alumnos` | HU-AD-12 | Lista de cuentas, activar/desactivar |

## Iteración 3 — Incidencias

| Pantalla ID | HU | Notas de diseño |
|---|---|---|
| `alumno_reportar_incidencia` | HU-AL-06 | Tipo de problema + descripción obligatoria → muestra folio |
| `alumno_mis_reportes` | HU-AL-07 | Lista con chips de estado + detalle con solución del técnico |
| `soporte_lista_incidencias` | HU-ST-02 | Filtros estado/lab/fecha + pull-to-refresh + vacío |
| `soporte_detalle_incidencia` | HU-ST-03/04/05 | Datos del equipo + "Tomar incidencia" + cambiar estado |
| `soporte_registrar_solucion` | HU-ST-06 | Textarea obligatoria para marcar "Resuelta" |
| `soporte_identificar_equipo` | HU-ST-03 | Ficha del equipo y su ubicación |

## Iteración 4 — Supervisión y consulta

| Pantalla ID | HU | Notas de diseño |
|---|---|---|
| `soporte_historial` | HU-ST-07 | Lista histórica con búsqueda |
| `admin_historial_uso` | HU-AD-08 | Tabla/filtros por alumno, equipo y rango de fechas |
| `admin_supervisar_incidencias` | HU-AD-09 | Vista global con estados y SLA |
| `admin_estadisticas` | HU-AD-10 | KPI cards + gráficas + filtros por periodo |

## Iteración 5 — Mejoras

| Pantalla ID | HU | Notas de diseño |
|---|---|---|
| `alumno_adjuntar_foto` | HU-AL-08 | Cámara/galería, miniaturas, eliminar |
| `notificaciones` | HU-AL-09 / HU-ST-08 | Centro de notificaciones con badge |
| `soporte_escanear_sitio` | HU-ST-09 | Escáner para verificar equipo en sitio |
| `admin_exportar_reportes` | HU-AD-11 | Selector de periodo + formato (PDF/Excel) |
| `dialog_cerrar_sesion` | HU-GEN-02 | Diálogo de confirmación |

---

# PARTE D — CHECKLIST DE ACEPTACIÓN DEL PROTOTIPO

Antes de aceptar Stitch, verifica:

- [ ] **Mobile-first**: se ve bien a 320 px sin scroll horizontal.
- [ ] **3 breakpoints**: tablet y desktop reorganizan el layout (no solo escalan).
- [ ] **Navegación por rol**: no aparecen destinos de otro rol.
- [ ] **Componentes reutilizados**: no hay botones/tarjetas "inventados" fuera de la 5.4.
- [ ] **Tokens respetados**: colores, tipografía, espaciado 8 dp, radios.
- [ ] **Estados completos**: carga, datos, vacío, error y sin conexión.
- [ ] **Validaciones**: errores inline bajo el campo, nunca solo en color.
- [ ] **CTA en zona del pulgar** y áreas táctiles ≥ 48 px.
- [ ] **Contraste AA** en texto y chips de estado.
- [ ] **Español neutro**, sin anglicismos en la UI.
- [ ] **Datos mock consistentes** con la sección 8 (mismos nombres y folios).
- [ ] **Código entregado** autocontenido y responsive (revisar media queries/clases).
- [ ] **Log-out visible** y confirmación antes de acciones destructivas.
- [ ] **Mensajes de login genéricos** (no revelan qué campo falló).

---

## 🧩 Ejemplo de prompt corto (lista de incidencias)

```
PANTALLA: Lista de incidencias | ID: HU-ST-02 | Rol: Soporte técnico

Como técnico de soporte, quiero ver la lista de incidencias reportadas por los
alumnos, para conocer qué problemas hay pendientes de atender.

CONTENIDO: AppBar "Incidencias" + buscador; chips de filtro (Estado, Laboratorio,
Fecha); tarjetas con folio INC-2026-00xx, chip de estado (Pendiente/En atención/
Resuelta), equipo PC-xx, laboratorio, tipo de problema y fecha; orden: pendientes
primero, más antigua primero; pull-to-refresh; empty state "No hay incidencias
pendientes"; skeleton de carga.

REGLAS: tokens Material 3 de la sección 5, filas 64–72 px, áreas táctiles 48 px,
CTA "Refrescar" como ícono en AppBar, restricción: el soporte NO ve equipos ni
personal.

RESPONSIVE: móvil 1 columna + Bottom Nav; tablet 600–1023 px lista a la izquierda
y detalle a la derecha (master-detail), Rail de navegación, contenido 900 px;
desktop ≥1024 px tabla densa con 4 columnas y contenido 1200 px; sin overflow.

ENTREGABLE: mockup mobile-first + código HTML/CSS responsive autocontenido con los
3 breakpoints + variantes tablet y desktop. Datos mock de la sección 8.
```

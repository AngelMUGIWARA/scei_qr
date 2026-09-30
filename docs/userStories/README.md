# Backlog de historias de usuario

### Sistema móvil y web para el control de uso e incidencias de equipos de cómputo mediante códigos QR

*Desarrollo móvil integral — Metodología Extreme Programming (XP)*

---

## 1. Introducción

Este backlog reúne las historias de usuario iniciales del proyecto. Cada historia vive en su propio archivo `.md`, organizado por rol, con el formato **Como [rol], quiero [funcionalidad], para [beneficio]**, criterios de aceptación en forma de checklist (pruebas de aceptación) y una lista de tareas de ingeniería para el desarrollo con Extreme Programming (XP).

El sistema tiene tres roles: **Alumno** y **Soporte técnico**, que usan la aplicación móvil, y **Administrador**, que usa la aplicación web. Cada computadora se identifica mediante un código QR único.

## 2. Cómo leer este backlog

| Campo | Significado |
|---|---|
| **ID** | `HU-[rol]-[número]`. GEN = transversal, AL = alumno, ST = soporte técnico, AD = administrador. |
| **Prioridad** | **Alta**: indispensable para el flujo principal. **Media**: importante, puede entrar en una iteración posterior. **Baja**: mejora deseable. |
| **Plataforma** | Móvil (alumno y soporte técnico), Web (administrador) o ambas. |
| **Origen** | **Documento**: se desprende directamente del documento del proyecto. **Propuesta**: historia añadida para completar el flujo; debe validarla el equipo. |
| **Dependencias** | Historias que deben estar terminadas o disponibles antes de esta. |

## 3. Estados de una incidencia

| Estado | Descripción | Quién lo genera |
|---|---|---|
| Pendiente | La incidencia fue reportada y aún no tiene técnico asignado. | Alumno, al reportar |
| En atención | Un técnico tomó la incidencia y está trabajando en ella. | Soporte técnico, al tomarla |
| Resuelta | El técnico aplicó y registró una solución. | Soporte técnico, al registrar la solución |

*Catálogo inicial; puede ampliarse (por ejemplo con "Cerrada" o "Cancelada") si el equipo lo considera necesario.*

## 4. Índice del backlog

**32 historias** en total: 2 en transversales, 9 en alumno, 9 en soporte tecnico, 12 en administrador.

| ID | Historia | Plataforma | Prioridad | Origen | Archivo |
|---|---|---|---|---|---|
| **Historias transversales** | | | | | |
| HU-GEN-01 | Control de acceso por rol | Móvil y Web | Alta | Propuesta | [transversales/HU-GEN-01-control-acceso.md](transversal/HU-GEN-01-control-acceso.md) |
| HU-GEN-02 | Cerrar sesión | Móvil y Web | Media | Propuesta | [transversales/HU-GEN-02-cerrar-sesion.md](transversal/HU-GEN-02-cerrar-sesion.md) |
| **Alumno — Aplicación móvil** | | | | | |
| HU-AL-01 | Iniciar sesión | Móvil | Alta | Documento | [alumno/HU-AL-01-iniciar-sesion.md](student/HU-AL-01-iniciar-sesion.md) |
| HU-AL-02 | Escanear el código QR de una computadora | Móvil | Alta | Documento | [alumno/HU-AL-02-escanear-qr.md](student/HU-AL-02-escanear-qr.md) |
| HU-AL-03 | Registrar el uso de un equipo | Móvil | Alta | Documento | [alumno/HU-AL-03-registrar-uso.md](student/HU-AL-03-registrar-uso.md) |
| HU-AL-04 | Finalizar el uso de un equipo | Móvil | Media | Propuesta | [alumno/HU-AL-04-finalizar-uso.md](student/HU-AL-04-finalizar-uso.md) |
| HU-AL-05 | Consultar mis registros de uso | Móvil | Media | Documento | [alumno/HU-AL-05-consultar-registros.md](student/HU-AL-04-consultar-registros.md) |
| HU-AL-06 | Reportar una incidencia de un equipo | Móvil | Alta | Documento | [alumno/HU-AL-06-reportar-incidencia.md](student/HU-AL-05-reportar-incidencia.md) |
| HU-AL-07 | Consultar el estado de mis reportes | Móvil | Alta | Documento | [alumno/HU-AL-07-consultar-reportes.md](student/HU-AL-06-consultar-reportes.md) |
| HU-AL-08 | Adjuntar una foto al reporte | Móvil | Baja | Propuesta | [alumno/HU-AL-08-adjuntar-foto.md](student/HU-AL-07-adjuntar-foto.md) |
| HU-AL-09 | Recibir notificación de cambio de estado | Móvil | Baja | Propuesta | [alumno/HU-AL-09-notificacion-cambio-estado.md](student/HU-AL-08-notificacion-cambio-estado.md) |
| **Soporte técnico — Aplicación móvil** | | | | | |
| HU-ST-01 | Iniciar sesión | Móvil | Alta | Documento | [soporte-tecnico/HU-ST-01-iniciar-sesion.md](technical-support/HU-ST-01-iniciar-sesion.md) |
| HU-ST-02 | Consultar las incidencias reportadas | Móvil | Alta | Documento | [soporte-tecnico/HU-ST-02-consultar-incidencias.md](technical-support/HU-ST-02-consultar-incidencias.md) |
| HU-ST-03 | Identificar la computadora y su ubicación | Móvil | Alta | Documento | [soporte-tecnico/HU-ST-03-identificar-computadora.md](technical-support/HU-ST-03-identificar-computadora.md) |
| HU-ST-04 | Tomar una incidencia para su atención | Móvil | Alta | Documento | [soporte-tecnico/HU-ST-04-tomar-incidencia.md](technical-support/HU-ST-04-tomar-incidencia.md) |
| HU-ST-05 | Actualizar el estado de una incidencia | Móvil | Alta | Documento | [soporte-tecnico/HU-ST-05-actualizar-estado.md](technical-support/HU-ST-05-actualizar-estado.md) |
| HU-ST-06 | Registrar la solución aplicada | Móvil | Alta | Documento | [soporte-tecnico/HU-ST-06-registrar-solucion.md](technical-support/HU-ST-06-registrar-solucion.md) |
| HU-ST-07 | Consultar el historial de incidencias atendidas | Móvil | Media | Documento | [soporte-tecnico/HU-ST-07-consultar-historial.md](technical-support/HU-ST-07-consultar-historial.md) |
| HU-ST-08 | Recibir notificación de nuevas incidencias | Móvil | Media | Propuesta | [soporte-tecnico/HU-ST-08-notificacion-nuevas-incidencias.md](technical-support/HU-ST-08-notificacion-nuevas-incidencias.md) |
| HU-ST-09 | Escanear el QR del equipo en sitio | Móvil | Baja | Propuesta | [soporte-tecnico/HU-ST-09-escanear-qr-sitio.md](technical-support/HU-ST-09-escanear-qr-sitio.md) |
| **Administrador — Aplicación web** | | | | | |
| HU-AD-01 | Iniciar sesión en la aplicación web | Web | Alta | Propuesta | [administrador/HU-AD-01-iniciar-sesion-web.md](admin/HU-AD-01-iniciar-sesion-web.md) |
| HU-AD-02 | Registrar personal de soporte técnico | Web | Alta | Documento | [administrador/HU-AD-02-registrar-soporte.md](admin/HU-AD-02-registrar-soporte.md) |
| HU-AD-03 | Administrar personal de soporte técnico | Web | Media | Documento | [administrador/HU-AD-03-administrar-soporte.md](admin/HU-AD-03-administrar-soporte.md) |
| HU-AD-04 | Registrar equipos de cómputo | Web | Alta | Documento | [administrador/HU-AD-04-registrar-equipos.md](admin/HU-AD-04-registrar-equipos.md) |
| HU-AD-05 | Administrar equipos de cómputo | Web | Media | Documento | [administrador/HU-AD-05-administrar-equipos.md](admin/HU-AD-05-administrar-equipos.md) |
| HU-AD-06 | Generar el código QR único de cada equipo | Web | Alta | Documento | [administrador/HU-AD-06-generar-qr.md](admin/HU-AD-06-generar-qr.md) |
| HU-AD-07 | Descargar e imprimir los códigos QR | Web | Media | Documento | [administrador/HU-AD-07-descargar-imprimir-qr.md](admin/HU-AD-07-descargar-imprimir-qr.md) |
| HU-AD-08 | Consultar el historial de uso de los equipos | Web | Alta | Documento | [administrador/HU-AD-08-consultar-historial-uso.md](admin/HU-AD-08-consultar-historial-uso.md) |
| HU-AD-09 | Consultar y supervisar las incidencias | Web | Alta | Documento | [administrador/HU-AD-09-supervisar-incidencias.md](admin/HU-AD-09-supervisar-incidencias.md) |
| HU-AD-10 | Consultar estadísticas y reportes del sistema | Web | Media | Documento | [administrador/HU-AD-10-estadisticas-reportes.md](admin/HU-AD-10-estadisticas-reportes.md) |
| HU-AD-11 | Exportar reportes | Web | Baja | Propuesta | [administrador/HU-AD-11-exportar-reportes.md](admin/HU-AD-11-exportar-reportes.md) |
| HU-AD-12 | Gestionar cuentas de alumnos | Web | Media | Propuesta | [administrador/HU-AD-12-gestionar-alumnos.md](admin/HU-AD-12-gestionar-alumnos.md) |

## 5. Estructura de carpetas

```
docs/user-stories/
├── README.md
├── transversales/
│   ├── HU-GEN-01-control-acceso.md
│   └── HU-GEN-02-cerrar-sesion.md
├── alumno/
│   ├── HU-AL-01-iniciar-sesion.md
│   ├── HU-AL-02-escanear-qr.md
│   ├── HU-AL-03-registrar-uso.md
│   ├── HU-AL-04-finalizar-uso.md
│   ├── HU-AL-05-consultar-registros.md
│   ├── HU-AL-06-reportar-incidencia.md
│   ├── HU-AL-07-consultar-reportes.md
│   ├── HU-AL-08-adjuntar-foto.md
│   └── HU-AL-09-notificacion-cambio-estado.md
├── soporte-tecnico/
│   ├── HU-ST-01-iniciar-sesion.md
│   ├── HU-ST-02-consultar-incidencias.md
│   ├── HU-ST-03-identificar-computadora.md
│   ├── HU-ST-04-tomar-incidencia.md
│   ├── HU-ST-05-actualizar-estado.md
│   ├── HU-ST-06-registrar-solucion.md
│   ├── HU-ST-07-consultar-historial.md
│   ├── HU-ST-08-notificacion-nuevas-incidencias.md
│   └── HU-ST-09-escanear-qr-sitio.md
└── administrador/
    ├── HU-AD-01-iniciar-sesion-web.md
    ├── HU-AD-02-registrar-soporte.md
    ├── HU-AD-03-administrar-soporte.md
    ├── HU-AD-04-registrar-equipos.md
    ├── HU-AD-05-administrar-equipos.md
    ├── HU-AD-06-generar-qr.md
    ├── HU-AD-07-descargar-imprimir-qr.md
    ├── HU-AD-08-consultar-historial-uso.md
    ├── HU-AD-09-supervisar-incidencias.md
    ├── HU-AD-10-estadisticas-reportes.md
    ├── HU-AD-11-exportar-reportes.md
    └── HU-AD-12-gestionar-alumnos.md
```

## 6. Iteraciones (Milestones)

XP trabaja con ciclos cortos y entregas incrementales. Cada iteración puede mapearse a un *Milestone* de GitHub.

| Iteración | Objetivo | Historias |
|---|---|---|
| 1 | Base del sistema: acceso, inventario de equipos y códigos QR. | HU-GEN-01, HU-AL-01, HU-ST-01, HU-AD-01, HU-AD-02, HU-AD-04, HU-AD-06 |
| 2 | Flujo del alumno: escaneo y registro de uso. | HU-AL-02, HU-AL-03, HU-AL-04, HU-AL-05, HU-AD-12* |
| 3 | Incidencias: reporte por el alumno y atención por soporte técnico. | HU-AL-06, HU-AL-07, HU-ST-02, HU-ST-03, HU-ST-04, HU-ST-05, HU-ST-06 |
| 4 | Supervisión y consulta: historiales, gestión y estadísticas del administrador. | HU-ST-07, HU-AD-03, HU-AD-05, HU-AD-07, HU-AD-08, HU-AD-09, HU-AD-10, HU-GEN-02 |
| 5 | Mejoras: notificaciones, evidencia fotográfica, escaneo por soporte y exportación. | HU-AL-08, HU-AL-09, HU-ST-08, HU-ST-09, HU-AD-11 |

\* `HU-AD-12` debe refinarse antes de entrar a desarrollo, ya que aún no cumple la Definition of Ready.

## 7. Gobierno del proceso

### Definition of Ready (DoR) y Definition of Done (DoD)

| Definition of Ready (para iniciar) | Definition of Done (para cerrar) |
|---|---|
| Está claramente redactada. | La funcionalidad está implementada. |
| Identifica al usuario o rol involucrado. | Cumple los criterios de aceptación. |
| Define el resultado esperado. | Las pruebas correspondientes fueron realizadas. |
| Cuenta con criterios de aceptación. | Los errores encontrados fueron corregidos. |
| No tiene dependencias o dudas importantes sin resolver. | El código pasó por Code Review (Pull Request). |
| El equipo comprende lo que debe realizarse. | Los cambios se integraron correctamente al repositorio. |
| Se puede dividir en tareas cuando es necesario. | La funcionalidad fue validada por el equipo. |

### Flujo de trabajo por historia

Historia de usuario → Definition of Ready → Desarrollo → Pruebas → Code Review → Definition of Done → Integración.

### Mapeo con GitHub

| Elemento XP | Equivalente en GitHub |
|---|---|
| Historia de usuario | Un *Issue* con el contenido del archivo `.md` (ej. `#12: [HU-AL-02] Escanear QR`). |
| Iteración | Un *Milestone* de GitHub (ej. `Iteración 1`, `Iteración 2`). |
| Desarrollo | Rama por historia (`feature/HU-AL-02-escanear-qr`). |
| Definition of Done | Checklist dentro del Pull Request antes de hacer *merge* a `main` o `develop`. |

# Plan: Backend del sistema (NestJS + PostgreSQL)

**Proyecto:** `scei_qr` (app Flutter) + `scei_qr_api` (backend NestJS)
**Backlog cubierto:** las 32 historias de usuario (HU-GEN-*, HU-AL-*, HU-ST-*, HU-AD-*)
**Fecha:** 2026-10-20
**Relacionado:** [arquitectura-login-sesion.md](./arquitectura-login-sesion.md) (cliente Flutter que consume esta API)

---

## 1. Decisión de tecnología

| Capa | Elección | Motivo |
|---|---|---|
| Runtime | **Node.js 20 LTS** | Ecosistema maduro, despliegue barato |
| Framework | **NestJS (TypeScript)** | Módulos, guards de roles, DTOs e inyección de dependencias = espejo de la Clean Architecture del cliente |
| ORM | **Prisma** | Migraciones, tipos generados y consultas tipadas |
| Base de datos | **PostgreSQL** | Robusto, gratis (Neon/Supabase/Render) |
| Auth | **JWT (access token) + bcrypt** | Contrato ya asumido por el cliente (`role` y `exp` en el token) |
| Documentación | **@nestjs/swagger** | Define el contrato OpenAPI que consume `HttpAuthDataSource` |
| QR | **qrcode** (npm) | Generación del QR único por equipo (HU-AD-06/07) |
| Push | **firebase-admin** | Notificaciones FCM (HU-AL-09, HU-ST-08) |
| Exportación | **exceljs / pdfmake** | Reportes (HU-AD-11) |
| Pruebas | **Jest + supertest** | Cumple el DoD de XP |

*Alternativa evaluada: FastAPI (Python). Se eligió NestJS por su estructura idéntica a la ya planeada en el cliente y por el tipado del contrato de API.*

---

## 2. Estructura del proyecto

Crear en una carpeta hermana: `INTEGRADORA MOVIL/scei_qr_api/`

```
scei_qr_api/
├── prisma/
│   ├── schema.prisma              # modelo de datos
│   ├── migrations/
│   └── seed.ts                    # usuarios de prueba (3 roles) y equipos demo
├── src/
│   ├── main.ts                    # bootstrap:Swagger, ValidationPipe, CORS
│   ├── app.module.ts              # módulos raíz
│   ├── common/
│   │   ├── guards/jwt-auth.guard.ts      # valida token JWT
│   │   ├── guards/roles.guard.ts         # HU-GEN-01: control por rol
│   │   ├── decorators/roles.decorator.ts # @Roles('ADMIN')
│   │   ├── decorators/current-user.decorator.ts
│   │   ├── filters/http-exception.filter.ts  # errores tipados y genéricos
│   │   └── interceptors/logging.interceptor.ts
│   ├── modules/
│   │   ├── auth/                  # login, logout, refresh (HU-AL-01, HU-ST-01, HU-AD-01)
│   │   ├── usuarios/              # alumnos y soporte (HU-AD-02/03, HU-AD-12)
│   │   ├── equipos/               # CRUD equipos + QR (HU-AD-04/05/06/07, HU-ST-03)
│   │   ├── usos/                  # registro de uso de equipos (HU-AL-03/04/05, HU-AD-08)
│   │   ├── incidencias/           # reportes y estados (HU-AL-06/07, HU-ST-02/04/05/06/07, HU-AD-09)
│   │   ├── reportes/              # estadísticas y exportación (HU-AD-10/11)
│   │   └── notificaciones/        # FCM push (HU-AL-09, HU-ST-08)
│   └── config/                    # variables de entorno (app.config.ts)
├── test/                          # pruebas e2e por módulo
├── .env.example
├── Dockerfile
└── package.json
```

Cada módulo sigue el mismo patrón: `*.controller.ts` → `*.service.ts` → `prisma.service.ts`.

---

## 3. Modelo de datos (Prisma)

```prisma
enum Rol        { ALUMNO  SOPORTE  ADMIN }
enum EstadoUso  { ACTIVO  FINALIZADO }
enum EstadoIncidencia { PENDIENTE  EN_ATENCION  RESUELTA }

model Usuario {
  id           Int      @id @default(autoincrement())
  username     String   @unique
  passwordHash String
  fullName     String
  rol          Rol
  activo       Boolean  @default(true)
  createdAt    DateTime @default(now())
  usos         Uso[]
  incidencias  Incidencia[]
}

model Equipo {
  id         Int      @id @default(autoincrement())
  codigo     String   @unique   // código interno del equipo
  nombre     String
  descripcion String?
  ubicacion  String              // laboratorio, salón, fila (HU-ST-03)
  qrToken    String   @unique   // payload del QR único (HU-AD-06)
  activo     Boolean  @default(true)
  usos       Uso[]
  incidencias Incidencia[]
}

model Uso {
  id         Int        @id @default(autoincrement())
  alumno     Usuario    @relation(fields: [alumnoId], references: [id])
  alumnoId   Int
  equipo     Equipo     @relation(fields: [equipoId], references: [id])
  equipoId   Int
  inicio     DateTime   @default(now())
  fin        DateTime?
  estado     EstadoUso  @default(ACTIVO)
}

model Incidencia {
  id          Int               @id @default(autoincrement())
  equipo      Equipo            @relation(fields: [equipoId], references: [id])
  equipoId    Int
  reportadaPor Usuario          @relation(fields: [reportadaPorId], references: [id])
  reportadaPorId Int
  atendidaPor Usuario?          @relation(fields: [atendidaPorId], references: [id])
  atendidaPorId Int?
  titulo      String
  descripcion String
  fotoUrl     String?                    // HU-AL-08 (storage: local / S3 / Cloudinary)
  estado      EstadoIncidencia @default(PENDIENTE)
  solucion    String?
  creadaEn    DateTime         @default(now())
  actualizadaEn DateTime       @updatedAt
}
```

---

## 4. Contrato de API (resumen)

Base: `/api/v1`. Todas las rutas protegidas envían `Authorization: Bearer <jwt>`.

| Método | Ruta | Rol permitido | Historia |
|---|---|---|---|
| POST | `/auth/login` | público | HU-AL-01, HU-ST-01, HU-AD-01 |
| POST | `/auth/logout` | autenticado | HU-GEN-02 |
| GET | `/usuarios` | ADMIN | HU-AD-03, HU-AD-12 |
| POST | `/usuarios` | ADMIN | HU-AD-02, HU-AD-12 |
| PATCH | `/usuarios/:id` | ADMIN | HU-AD-03, HU-AD-12 |
| GET | `/equipos` | autenticado | HU-AD-05 |
| POST | `/equipos` | ADMIN | HU-AD-04 |
| PATCH | `/equipos/:id` | ADMIN | HU-AD-05 |
| GET | `/equipos/:id/qr` | ADMIN | HU-AD-06 (devuelve PNG/SVG del QR) |
| GET | `/equipos/qr/:qrToken` | autenticado | HU-AL-02, HU-ST-03 (resuelve el QR escaneado) |
| POST | `/usos` | ALUMNO | HU-AL-03 (body: `qrToken`) |
| PATCH | `/usos/:id/finalizar` | ALUMNO | HU-AL-04 |
| GET | `/usos/mis-registros` | ALUMNO | HU-AL-05 |
| GET | `/usos/historial?equipoId=` | ADMIN | HU-AD-08 |
| POST | `/incidencias` | ALUMNO | HU-AL-06 (multipart con foto) |
| GET | `/incidencias/mis-reportes` | ALUMNO | HU-AL-07 |
| GET | `/incidencias?estado=` | SOPORTE, ADMIN | HU-ST-02, HU-AD-09 |
| PATCH | `/incidencias/:id/tomar` | SOPORTE | HU-ST-04 (PENDIENTE → EN_ATENCION) |
| PATCH | `/incidencias/:id/estado` | SOPORTE | HU-ST-05 |
| PATCH | `/incidencias/:id/solucion` | SOPORTE | HU-ST-06 (→ RESUELTA + texto solución) |
| GET | `/incidencias/historial` | SOPORTE | HU-ST-07 |
| GET | `/reportes/estadisticas` | ADMIN | HU-AD-10 |
| GET | `/reportes/exportar?format=xlsx\|pdf` | ADMIN | HU-AD-11 |

### Reglas de negocio clave

1. **Login**: credenciales inválidas o cuenta inactiva → error **genérico** `401 "Usuario o contraseña incorrectos"` (no revelar cuál falló, CA de HU-AL-01).
2. **Token JWT**: payload `{ sub, username, role }`, expiración 8h. El cliente valida `exp` con `jwt_decoder`.
3. **Transiciones de incidencia**: solo `PENDIENTE → EN_ATENCION → RESUELTA`; un `PATCH` fuera de orden devuelve `409 Conflict`.
4. **Tomar incidencia**: debe fallar si alguien más ya la tomó (condición transaccional en Prisma).
5. **Uso de equipo**: solo un `Uso` ACTIVO por alumno a la vez; escanear otro QR con uso activo → `409`.

---

## 5. Pasos de creación (checklist)

```bash
# 1. Crear el proyecto (carpeta hermana de scei_qr)
npx @nestjs/cli new scei_qr_api --package-manager npm
cd scei_qr_api

# 2. Prisma + PostgreSQL
npm i @prisma/client
npm i -D prisma
npx prisma init --datasource-provider postgresql
# Editar prisma/schema.prisma con el modelo de la sección 3
npx prisma migrate dev --name init
npx prisma db seed

# 3. Dependencias principales
npm i @nestjs/config @nestjs/jwt @nestjs/passport passport passport-jwt bcrypt
npm i class-validator class-transformer @nestjs/swagger
npm i qrcode firebase-admin exceljs pdfmake multer
npm i -D @nestjs/testing @types/passport-jwt @types/bcrypt @types/multer

# 4. Módulos en orden de desarrollo (siguiendo las iteraciones del backlog)
nest g resource modules/auth --no-spec        # Iteración 1
nest g resource modules/usuarios --no-spec    # Iteración 1
nest g resource modules/equipos --no-spec     # Iteración 1
nest g resource modules/usos --no-spec        # Iteración 2
nest g resource modules/incidencias --no-spec # Iteración 3
nest g resource modules/reportes --no-spec    # Iteración 4
nest g resource modules/notificaciones --no-spec # Iteración 5

# 5. Variables de entorno (.env)
# DATABASE_URL, JWT_SECRET, JWT_EXPIRATION=8h, PORT=3000
# FIREBASE_SERVICE_ACCOUNT (base64, para push en Iteración 5)
# STORAGE_DRIVER=local|s3|cloudinary (fotos, Iteración 5)

# 6. Levantar
npm run start:dev        # http://localhost:3000/api/docs (Swagger)
```

---

## 6. Mapeo iteraciones (backlog ↔ backend)

| Iteración | Backend incluye |
|---|---|
| **1** (acceso + equipos + QR) | `auth`, `usuarios`, `equipos` con generación de QR; seed con los 3 usuarios de prueba; login entrega JWT con `role` |
| **2** (uso del alumno) | `usos`: iniciar con `qrToken`, finalizar, consultar mis registros; reglas de uso único activo |
| **3** (incidencias) | `incidencias`: crear con foto, listar por rol, máquina de estados, tomar incidencia, registrar solución |
| **4** (supervisión) | `reportes`: estadísticas (usos por equipo, incidencias por estado/técnico) y exportación xlsx/pdf; historiales |
| **5** (mejoras) | `notificaciones` FCM, fotos en S3/Cloudinary, QR por soporte en sitio |

---

## 7. Pruebas (DoD de XP)

- **Unitarias (Jest):** servicios de `auth` (login ok/invalido/inactivo), `incidencias` (transiciones válidas e inválidas, tomar en paralelo), `usos` (uso duplicado).
- **E2E (supertest):** flujo login → crear equipo → generar QR → alumno escanea (usa `qrToken`) → inicia uso → reporta incidencia → soporte toma → resuelve → admin consulta estadísticas.
- **Contrato:** validar con Swagger que las respuestas calzan con `AuthResponseModel` del cliente.

---

## 8. Despliegue

| Entorno | Opción |
|---|---|
| Desarrollo | Docker Compose (Postgres local) o Neon/Supabase free |
| Demo/producción | Render / Railway (free tier) + Neon (Postgres free) |
| Producción real | VPS (DigitalOcean/Hetzner) con Docker + Caddy/Nginx, o contenedor en la infraestructura de la institución |

CI: GitHub Actions — en cada PR correr `npm run test` y `npx prisma migrate deploy` antes del merge (exigido por el DoD).

---

## 9. Interfaz con el cliente Flutter

Al terminar cada iteración, actualizar en `scei_qr`:

1. `AppConfig.baseUrl` (via `--dart-define=API_URL=...`).
2. `MockAuthDataSource` → `HttpAuthDataSource` (cambio de inyección en `main()`, sin tocar UI ni Dominio).
3. Documentar cada endpoint en Swagger antes de consumirlo desde Flutter (el Swagger es la fuente de verdad del contrato).

# Plan: Login móvil, consumo de autenticación y almacenamiento seguro de sesión

**Proyecto:** `scei_qr` (Flutter)
**Historias cubiertas:** HU-AL-01, HU-ST-01, HU-AD-01, HU-GEN-01 (parcial, lado cliente), HU-GEN-02 (parcial)
**Fecha:** 2026-10-19 · **Actualizado:** 2026-10-28

> **Actualización (2026-10-28, rama `feature/HU-AL-01-login-sesion`)**
> - **Sí hay backend**: `../scei_qr_api` (NestJS) ya expone `POST /api/v1/auth/login` y
>   `POST /api/v1/auth/logout`; el contrato real está en Swagger (`http://localhost:3000/api/docs`)
>   y en [arquitectura-backend.md](./arquitectura-backend.md) §4. Por eso **no se usa el mock**
>   de la §7: la implementación real es `HttpAuthDataSource`.
> - **La entidad de sesión ya existe en el dominio**: se usa `lib/dominio/sesion.dart` (`Sesion` + `Rol`),
>   el contrato compartido con el guard de HU-GEN-01, en lugar de una `UserSession` nueva.
> - Usuarios seed reales: `admin`, `soporte`, `alumno1`, `alumno2` → `Password123!`.
> - Quedan fuera de esta tarea: logout (HU-GEN-02) y la expiración por inactividad.

## 1. Contexto y estado actual

- La app arrancaba con la demo del contador; ahora `lib/main.dart` hace el ensamblado de dependencias y arranca en `SplashScreen`.
- Existe un backlog de historias de usuario en `docs/user-stories/` (32 historias, metodología XP).
- El backend real vive en la carpeta hermana `../scei_qr_api` y su contrato es la fuente de verdad.

## 2. Arquitectura propuesta: Clean Architecture ligera (capas por feature)

```
Presentación (widgets, providers)  →  Dominio (entidades, casos de uso, contratos)  →  Datos (models, datasources, repositorios)
```

### Patrones de diseño

| Patrón | Uso en el proyecto |
|---|---|
| **Repository** | `AuthRepository` abstracto en Dominio; `AuthRepositoryImpl` en Datos. Único punto de verdad de la sesión (API + almacenamiento). |
| **Use Case** | `LoginUseCase`, `LogoutUseCase`, `RestoreSessionUseCase` (una responsabilidad c/u, testables). |
| **Provider + ChangeNotifier** | `AuthProvider` con estados `initial / loading / authenticated(role) / unauthenticated / error`. |
| **DTO/Model** | `AuthResponseModel` con `fromJson`/`toJson` mapeando a `UserSession`. |
| **Inyección ligera** | Dependencias registradas en `main()` con `Provider` (nuevo `MultiProvider`). |

**Ventaja clave:** el DataSource es una interfaz con dos implementaciones (`Mock` y `Http`). Al llegar el backend real solo se cambia la implementación inyectada; la UI y el Dominio no se tocan.

## 3. Dependencias a agregar (`pubspec.yaml`)

- `provider` — gestión de estado.
- `http` — consumo REST futuro.
- `flutter_secure_storage` — token en Keychain (iOS) / Keystore (Android).
- `jwt_decoder` — extraer `role` y `exp` del JWT.

## 4. Estructura a crear

```
lib/
├── main.dart                                  # bootstrap, MultiProvider, rutas
├── dominio/
│   ├── sesion.dart                            # ENTIDAD de sesión (HU-GEN-01, compartida con el guard)
│   └── rol.dart                               # enum Rol { alumno, soporteTecnico, administrador }
├── core/
│   ├── config/app_config.dart                 # baseUrl vía --dart-define
│   ├── errors/app_exception.dart              # errores tipados (network/server/auth)
│   └── storage/secure_storage_service.dart    # wrapper de flutter_secure_storage
└── features/auth/
    ├── domain/
    │   ├── repositories/auth_repository.dart  # abstract: login, restoreSession (devuelve Sesion)
    │   └── usecases/
    │       ├── login_usecase.dart
    │       └── restore_session_usecase.dart
    ├── data/
    │   ├── models/auth_response_model.dart    # + mapeo ALUMNO/SOPORTE/ADMIN → Rol y expiraEn (JWT)
    │   ├── datasources/
    │   │   ├── auth_remote_data_source.dart       # interfaz
    │   │   └── http_auth_data_source.dart         # POST /api/v1/auth/login (real)
    │   └── repositories/auth_repository_impl.dart # orquesta API + secure storage
    └── presentation/
        ├── providers/auth_provider.dart
        ├── rol_ui.dart                        # Rol → ruta home y etiqueta
        └── screens/
            ├── splash_screen.dart             # restaura sesión
            ├── login_screen.dart              # formulario + validaciones
            ├── home_screen.dart               # ruteo por rol
            └── homes/{alumno,soporte,admin}_home.dart  # placeholders por rol
```

## 5. Flujo de sesión

1. **Splash**: ejecuta `RestoreSessionUseCase`.
   - Token presente y no expirado → `HomeScreen` según rol.
   - Sin token o expirado → borra storage → `LoginScreen`.
2. **Login**:
   - Validación de campos vacíos antes de enviar.
   - Spinner mientras carga (`loading`).
   - Credenciales inválidas / cuenta desactivada / error de red → mensaje **genérico**: *"Usuario o contraseña incorrectos"* (no revela cuál campo falló — CA de HU-AL-01).
   - Éxito → guarda token en secure storage → navega a Home según rol.
3. **Home por rol** (HU-GEN-01, parcial cliente):
   - Alumno / Soporte técnico / Administrador con su pantalla placeholder.
   - Opción visible de **"Cerrar sesión"** en el AppBar (HU-GEN-02).
4. **Logout**:
   - Confirmación → llama `LogoutUseCase` → borra token del secure storage → vuelve a `LoginScreen` como raíz (sin poder regresar con el botón "atrás").

## 6. Almacenamiento seguro

- Token **solo** en `flutter_secure_storage` (cifrado por Keychain/Keystore). Nunca en `SharedPreferences`.
- Se persisten: token JWT + datos mínimos del usuario (id, username, fullName, role).
- Al restaurar se valida `exp` del JWT con `jwt_decoder`; si expiró, se elimina y se va a Login.

## 7. Fuente de datos: API real (el mock quedó como alternativa de tests)

**Implementación entregada:** `HttpAuthDataSource` contra `../scei_qr_api` corriendo en
`http://localhost:3000/api/v1`. No se creó `MockAuthDataSource`: los datos de prueba
los cubren los tests con fakes (`test/fakes_auth.dart`).

Cuentas del seed (`npx prisma db seed` en `scei_qr_api`):

| Usuario | Contraseña | Rol |
|---|---|---|
| `alumno1` / `alumno2` | `Password123!` | Alumno |
| `soporte` | `Password123!` | Soporte técnico |
| `admin` | `Password123!` | Administrador |

- `AppConfig.apiBaseUrl` se inyecta con `--dart-define=API_URL=...`
  (emulador Android: `http://10.0.2.2:3000/api/v1`).

## 8. Pruebas (Definition of Done)

- **Unitarias**: `LoginUseCase` (éxito/error/vacíos), `AuthRepositoryImpl` (login, 3 roles, token válido/expirado/corrupto), `AuthProvider` (transiciones de estado y mensaje de error genérico), `HttpAuthDataSource` (200/400/401/500/sin red).
- **Widget**: validación de campos vacíos, error genérico con credenciales inválidas, navegación a Home por rol (alumno/soporte/admin).
- Resultado: `flutter analyze` sin issues y `flutter test` en verde (114 pruebas).

## 9. Criterios de aceptación que valida este plan

- HU-AL-01: formulario, acceso con credenciales válidas, error genérico con inválidas, validación de vacíos, sesión persistente.
- HU-ST-01 / HU-AD-01: mismo flujo con sus roles y pantalla principal correspondiente.
- HU-GEN-01 (cliente): ruteo de pantallas según rol.
- HU-GEN-02: **fuera de alcance de esta tarea** (cerrar sesión queda pendiente; el login usa `pushReplacement` para no volver atrás).

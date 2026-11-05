# scei_qr

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Conectar la app con el backend local

La app usa por defecto `http://localhost:3000/api/v1`. En Android, `localhost`
apunta al propio emulador o teléfono, no a la computadora donde corre el
backend. Para redirigir ese puerto se usa `adb reverse`.

### Requisitos

- Backend de `scei_qr_api_py` encendido y disponible en
  `http://localhost:3000/api/v1/health`.
- Flutter y Android SDK Platform-Tools instalados.
- Emulador Android iniciado o teléfono Android conectado por USB con depuración
  USB autorizada.

### Configurar el túnel

Con el emulador o el teléfono conectado, ejecutar desde la raíz del proyecto:

```powershell
dart run tool/setup_api_tunnel.dart
```

El script:

1. Verifica que el backend esté disponible.
2. Detecta `adb` automáticamente en Windows, macOS y Linux.
3. Configura `adb reverse tcp:3000 tcp:3000` en cada dispositivo conectado.

Después de eso, se puede ejecutar la app normalmente desde el IDE o con:

```powershell
flutter run -d <device-id>
```

También se puede configurar el túnel y lanzar Flutter en un solo paso:

```powershell
dart run tool/setup_api_tunnel.dart --device <device-id>
```

### Verificar y solucionar problemas

Comprobar que la redirección quedó activa:

```powershell
adb reverse --list
```

Debe aparecer al menos una entrada `tcp:3000 tcp:3000`.

- Si se desconecta el dispositivo o se reinicia `adb`, volver a ejecutar el
  script.
- Si no aparece el dispositivo, revisar `adb devices` y autorizar la depuración
  USB en el teléfono.
- Si el backend no responde, iniciarlo de nuevo con `docker compose up -d`
  dentro de `scei_qr_api_py`.
- Si no se encuentra `adb`, instalar Android SDK Platform-Tools o indicar la
  ruta con `--adb <ruta>`.

Este flujo cubre emulador Android y dispositivos Android por USB. Para un
backend compartido, usar HTTPS y compilar con:

```powershell
flutter run --dart-define=API_URL=https://<host>/api/v1
```

Para iPhone físico o Android por Wi-Fi sin `adb connect`, se requiere apuntar a
la IP de la computadora y habilitar HTTP solo en desarrollo.

// FASE 0 — REPRODUCCIÓN (archivo temporal de diagnóstico, no es una HU).
//
// Verifica contra la API real (FastAPI en http://localhost:3000/api/v1):
//   1. Que los 3 roles hacen login y mapean a su Rol de dominio.
//   2. Que las credenciales inválidas producen el error genérico.
//   3. Que develop actual NO restringe el rol (la restricción
//      `rolRequerido: Rol.administrador` de la rama HU-AD-01 fue eliminada
//      en la Fase 1 de limpieza del merge; aquí se deja constancia de que
//      los 3 roles entran y persisten/restauran su sesión).
//   4. Que AppConfig solo acepta HTTP para localhost/127.0.0.1/10.0.2.2
//      (la "IP forzada" que reporta el usuario).
//
// Requiere el backend arriba: docker compose up -d --build (scei_qr_api).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:scei_qr/core/config/app_config.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/core/storage/secure_storage_service.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/features/auth/data/datasources/http_auth_data_source.dart';
import 'package:scei_qr/features/auth/data/repositories/auth_repository_impl.dart';

const _api = 'http://localhost:3000/api/v1';

/// Almacenamiento en memoria: sustituye flutter_secure_storage en unit tests.
class _MemStorage extends SecureStorageService {
  final Map<String, String> _datos = {};

  @override
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    _datos['auth_session'] = jsonEncode({'token': token, 'user': userJson});
  }

  @override
  Future<String?> readSessionJson() async => _datos['auth_session'];

  @override
  Future<String?> readToken() async => _datos['auth_token'];

  @override
  Future<String?> readUserJson() async => _datos['auth_user'];

  @override
  Future<void> clearLegacySession() async {
    _datos.remove('auth_token');
    _datos.remove('auth_user');
  }

  @override
  Future<void> clear() async => _datos.clear();
}

HttpAuthDataSource _ds() => HttpAuthDataSource(baseUrl: _api);

void main() {
  setUpAll(() {
    // El backend debe estar corriendo; si no, estos tests fallan aquí mismo.
  });

  group('Fase 0.1 — login real de los 3 roles', () {
    for (final (username, rolEsperado) in [
      ('admin', Rol.administrador),
      ('soporte', Rol.soporteTecnico),
      ('alumno1', Rol.alumno),
    ]) {
      test('$username inicia sesión y mapea a ${rolEsperado.name}', () async {
        final sesion = await (_ds().login(username, 'Password123!'))
            .then((m) => m.toSession());
        expect(sesion.username, username);
        expect(sesion.rol, rolEsperado);
        expect(sesion.token, isNotEmpty);
        expect(sesion.estaVigente(DateTime.now()), isTrue);
      });
    }
  });

  group('Fase 0.2 — credenciales inválidas (mensaje genérico)', () {
    test('usuario inexistente → AuthException', () {
      expect(
        _ds().login('noexiste', 'Password123!'),
        throwsA(isA<AuthException>()),
      );
    });

    test('contraseña incorrecta → AuthException', () {
      expect(
        _ds().login('alumno1', 'mala1234'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('Fase 0.3 — ¿por qué "solo deja entrar el admin"?', () {
    test('develop actual: los 3 roles entran, persisten y restauran',
        () async {
      final storage = _MemStorage();
      final repo = AuthRepositoryImpl(remote: _ds(), storage: storage);

      for (final (username, rol) in [
        ('admin', Rol.administrador),
        ('soporte', Rol.soporteTecnico),
        ('alumno1', Rol.alumno),
      ]) {
        final sesion = await repo.login(username, 'Password123!');
        expect(sesion.rol, rol, reason: 'login de $username');

        // La sesión persistida se restaura con el mismo rol.
        final restaurada = await AuthRepositoryImpl(
          remote: _ds(),
          storage: storage,
        ).restoreSession();
        expect(restaurada?.rol, rol, reason: 'restore de $username');
      }
    });
  });

  group('Fase 0.4 — ¿por qué se fuerza una IP?', () {
    test('HTTP permitido solo para localhost / 127.0.0.1 / 10.0.2.2', () {
      AppConfig.validateBaseUrl('http://localhost:3000/api/v1');
      AppConfig.validateBaseUrl('http://127.0.0.1:3000/api/v1');
      AppConfig.validateBaseUrl('http://10.0.2.2:3000/api/v1');
      AppConfig.validateBaseUrl('https://api.ejemplo.com/api/v1');
    });

    test('una IP LAN (192.168.x.x) por HTTP es rechazada con ConfigException',
        () {
      expect(
        () => AppConfig.validateBaseUrl('http://192.168.1.10:3000/api/v1'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('el data source ni se construye con una IP LAN no permitida', () {
      expect(
        () => HttpAuthDataSource(baseUrl: 'http://192.168.1.10:3000/api/v1'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('por defecto API_URL apunta a localhost (obligatorio el dart-define)',
        () {
      expect(AppConfig.apiBaseUrl, 'http://localhost:3000/api/v1');
    });
  });
}

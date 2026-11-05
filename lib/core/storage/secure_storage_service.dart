import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper de `flutter_secure_storage` (arquitectura-login-sesion §6).
///
/// El token JWT vive **únicamente** aquí (Keychain en iOS / Keystore en
/// Android), nunca en SharedPreferences.
///
/// Tolerante a fallos: si el almacenamiento no está disponible (tests,
/// plataforma sin soporte) devuelve `null`/ignora en lugar de romper el
/// arranque de la app.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _sessionKey = 'auth_session';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Guarda el token y los datos mínimos de la sesión en una única estructura.
  /// Usa únicamente la clave [auth_session]. Si falla la escritura, se intenta
  /// limpiar todas las claves y se relanza el error para que el repositorio
  /// pueda manejarlo.
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    try {
      final combined = jsonEncode({'token': token, 'user': userJson});
      await _storage.write(key: _sessionKey, value: combined);
    } catch (e) {
      try {
        await clear();
      } catch (_) {}
      rethrow;
    }
  }

  Future<String?> readSessionJson() async {
    try {
      return await _storage.read(key: _sessionKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readAccessToken() async {
    final sessionJson = await readSessionJson();
    if (sessionJson != null) {
      try {
        final combined = jsonDecode(sessionJson) as Map<String, dynamic>;
        final token = combined['token'];
        if (token is String && token.isNotEmpty) return token;
      } catch (_) {
        return null;
      }
    }
    return readToken();
  }

  Future<String?> readUserJson() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
  }

  /// Borra solo las claves legacy (auth_token y auth_user).
  Future<void> clearLegacySession() async {
    Object? error;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      error = e;
    }
    try {
      await _storage.delete(key: _userKey);
    } catch (e) {
      error ??= e;
    }
    if (error != null) {
      throw error;
    }
  }

  /// Borra toda la sesión (clave unificada y claves antiguas).
  Future<void> clear() async {
    Object? error;
    try {
      await _storage.delete(key: _sessionKey);
    } catch (e) {
      error ??= e;
    }
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      error ??= e;
    }
    try {
      await _storage.delete(key: _userKey);
    } catch (e) {
      error ??= e;
    }
    if (error != null) {
      throw error;
    }
  }
}

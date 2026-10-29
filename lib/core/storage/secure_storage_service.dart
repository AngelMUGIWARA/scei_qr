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

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Guarda el token y los datos mínimos de la sesión.
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: userJson);
    } catch (_) {
      // Almacenamiento no disponible: se ignora (la sesión no se persiste).
    }
  }

  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> readUserJson() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
  }

  /// Borra toda la sesión (token + usuario).
  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {
      // Idem: si no hay storage no hay nada que borrar.
    }
  }
}

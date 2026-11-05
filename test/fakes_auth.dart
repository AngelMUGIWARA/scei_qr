// Fakes compartidos de las pruebas de autenticación (HU-AL-01).
// Este archivo no termina en _test.dart: no se ejecuta como prueba.


import 'dart:convert';

import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/core/storage/secure_storage_service.dart';
import 'package:scei_qr/dominio/rol.dart';
import 'package:scei_qr/dominio/sesion.dart';
import 'package:scei_qr/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:scei_qr/features/auth/data/models/auth_response_model.dart';
import 'package:scei_qr/features/auth/domain/repositories/auth_repository.dart';

/// Sesión de ejemplo futura (vigente).
Sesion sesionDePrueba({
  Rol rol = Rol.alumno,
  String username = 'alumno1',
  String nombreCompleto = 'Lucía Fernández',
}) {
  return Sesion(
    token: 'token-de-prueba',
    rol: rol,
    expiraEn: DateTime.now().add(const Duration(hours: 8)),
    usuarioId: 1,
    username: username,
    nombreCompleto: nombreCompleto,
  );
}

/// JWT sintético para las pruebas.
String jwtDePrueba({
  required DateTime expira,
  Map<String, dynamic>? claims,
}) {
  String parte(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

  return '${parte({'alg': 'HS256', 'typ': 'JWT'})}'
      '.${parte({
    'sub': 1,
    'username': 'alumno1',
    ...?claims,
    'exp': expira.toUtc().millisecondsSinceEpoch ~/ 1000,
  })}'
      '.firma';
}

/// Repositorio falso: controla el resultado de login, restore y logout.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.alLogin,
    this.alRestaurar,
    this.falloAlCerrar = false,
  });

  Future<Sesion> Function(String username, String password)? alLogin;
  Future<Sesion?> Function()? alRestaurar;

  /// Simula un fallo del almacenamiento seguro al borrar la sesión.
  bool falloAlCerrar;

  int loginLlamadas = 0;
  int restoreLlamadas = 0;
  int cerrarSesionLlamadas = 0;
  String? ultimoUsername;
  String? ultimoPassword;

  @override
  Future<Sesion> login(String username, String password) async {
    loginLlamadas++;
    ultimoUsername = username;
    ultimoPassword = password;
    final handler = alLogin;
    if (handler == null) throw const AuthException();
    return handler(username, password);
  }

  @override
  Future<Sesion?> restoreSession() async {
    restoreLlamadas++;
    final handler = alRestaurar;
    if (handler == null) return null;
    return handler();
  }

  @override
  Future<void> cerrarSesion() async {
    cerrarSesionLlamadas++;
    if (falloAlCerrar) throw Exception('almacenamiento no disponible');
  }
}

/// DataSource falso para probar el repositorio sin red.
class FakeRemoteDataSource implements AuthRemoteDataSource {
  FakeRemoteDataSource({this.respuesta, this.error});

  AuthResponseModel? respuesta;
  Object? error;

  int llamadas = 0;
  String? ultimoUsername;
  String? ultimoPassword;

  @override
  Future<AuthResponseModel> login(String username, String password) async {
    llamadas++;
    ultimoUsername = username;
    ultimoPassword = password;
    if (error != null) throw error!;
    return respuesta!;
  }
}

/// Almacenamiento en memoria: simula sesión unificada y claves legacy.
class FakeStorage extends SecureStorageService {
  String? sessionJson;
  String? token;
  String? userJson;
  bool fueLimpiado = false;
  int saveCount = 0;

  @override
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    saveCount++;
    this.token = token;
    this.userJson = userJson;
    sessionJson = jsonEncode({
      'token': token,
      'user': userJson,
    });
  }

  @override
  Future<String?> readSessionJson() async => sessionJson;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> clearLegacySession() async {
    token = null;
    userJson = null;
  }

  @override
  Future<void> clear() async {
    sessionJson = null;
    token = null;
    userJson = null;
    fueLimpiado = true;
  }
}

/// Respuesta simulada del backend.
AuthResponseModel respuestaLogin({
  String rol = 'ALUMNO',
  String? accessToken,
  int expiresIn = 28800,
}) {
  final token = accessToken ??
      jwtDePrueba(
        expira: DateTime.now().add(Duration(seconds: expiresIn)),
      );

  return AuthResponseModel(
    accessToken: token,
    tokenType: 'Bearer',
    expiresIn: expiresIn,
    id: 1,
    username: 'alumno1',
    fullName: 'Lucía Fernández',
    rol: rol,
  );
}

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

/// JWT sintético solo con `exp` (jwt_decoder no verifica la firma).
String jwtDePrueba({required DateTime expira}) {
  String parte(Object json) => base64Url
      .encode(utf8.encode(jsonEncode(json)))
      .replaceAll('=', '');
  return '${parte({'alg': 'HS256', 'typ': 'JWT'})}'
      '.${parte({'sub': 1, 'username': 'alumno1', 'exp': expira.toUtc().millisecondsSinceEpoch ~/ 1000})}'
      '.firma';
}

/// Repositorio falso: controla el resultado de login y restore.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.alLogin, this.alRestaurar});

  Future<Sesion> Function(String username, String password)? alLogin;
  Future<Sesion?> Function()? alRestaurar;

  int loginLlamadas = 0;
  int restoreLlamadas = 0;
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

/// Storage en memoria: evita el plugin nativo dentro de los tests.
class FakeStorage extends SecureStorageService {
  String? token;
  String? userJson;
  bool fueLimpiado = false;

  @override
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    this.token = token;
    this.userJson = userJson;
  }

  @override
  Future<String?> readToken() async => token;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> clear() async {
    token = null;
    userJson = null;
    fueLimpiado = true;
  }
}

/// Respuesta 200 del backend (contrato real de scei_qr_api).
AuthResponseModel respuestaLogin({
  String rol = 'ALUMNO',
  String accessToken = 'token',
  int expiresIn = 28800,
}) {
  return AuthResponseModel(
    accessToken: accessToken,
    tokenType: 'Bearer',
    expiresIn: expiresIn,
    id: 1,
    username: 'alumno1',
    fullName: 'Lucía Fernández',
    rol: rol,
  );
}

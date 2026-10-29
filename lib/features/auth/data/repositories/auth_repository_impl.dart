import 'dart:convert';

import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../dominio/rol.dart';
import '../../../../dominio/sesion.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementación del contrato [AuthRepository] (patrón Repository).
///
/// Coordina la fuente de datos (API) con el almacenamiento seguro: es el
/// único punto de verdad de la sesión. La serialización de [Sesion] vive
/// aquí porque la capa de datos es la dueña del formato persistido.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remote,
    required this.storage,
    this.rolRequerido,
  });

  final AuthRemoteDataSource remote;
  final SecureStorageService storage;
  final Rol? rolRequerido;

  @override
  Future<Sesion> login(String username, String password) async {
    final response = await remote.login(username, password);
    final sesion = response.toSession();

    _validarRol(sesion.rol);

    await storage.saveSession(
      token: sesion.token,
      userJson: jsonEncode(_aJson(sesion)),
    );

    return sesion;
  }

  @override
  Future<Sesion?> restoreSession() async {
    final token = await storage.readToken();
    final userJson = await storage.readUserJson();

    if (token == null || userJson == null) return null;

    // CA HU-AL-01 / HU-GEN-02: token vencido o no decodificable → se descarta.
    if (!_tokenVigente(token)) {
      await storage.clear();
      return null;
    }

    try {
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      final sesion = _aSesion(json, token);
      if (rolRequerido != null && sesion.rol != rolRequerido) {
        await storage.clear();
        return null;
      }
      return sesion;
    } catch (_) {
      // Registro corrupto: se limpia para no dejar la app en un estado raro.
      await storage.clear();
      return null;
    }
  }

  void _validarRol(Rol rol) {
    if (rolRequerido != null && rol != rolRequerido) {
      throw const AuthException(
        'Esta cuenta no tiene permisos de administrador',
      );
    }
  }

  Map<String, dynamic> _aJson(Sesion sesion) => {
    'usuarioId': sesion.usuarioId,
    'username': sesion.username,
    'nombreCompleto': sesion.nombreCompleto,
    'rol': sesion.rol.name,
    'expiraEn': sesion.expiraEn.toIso8601String(),
  };

  Sesion _aSesion(Map<String, dynamic> json, String token) {
    final rol = Rol.values.byName(json['rol'] as String);

    // El `exp` del JWT es la fuente de verdad de la expiración (§6 del plan).
    return Sesion(
      token: token,
      rol: rol,
      expiraEn: JwtDecoder.getExpirationDate(token),
      usuarioId: json['usuarioId'] as int,
      username: json['username'] as String,
      nombreCompleto: json['nombreCompleto'] as String,
    );
  }

  bool _tokenVigente(String token) {
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }
}

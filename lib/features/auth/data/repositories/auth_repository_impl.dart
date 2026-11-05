import 'dart:convert';

import 'package:jwt_decoder/jwt_decoder.dart';

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
  });

  final AuthRemoteDataSource remote;
  final SecureStorageService storage;

  @override
  Future<Sesion> login(String username, String password) async {
    final response = await remote.login(username, password);
    final sesion = response.toSession();

    await storage.saveSession(
      token: sesion.token,
      userJson: jsonEncode(_aJson(sesion)),
    );

    return sesion;
  }

  @override
  Future<Sesion?> restoreSession() async {
    // Intentar leer sesión unificada primero
    final sessionJson = await storage.readSessionJson();
    if (sessionJson != null) {
      try {
        final combined = jsonDecode(sessionJson) as Map<String, dynamic>;
        final token = combined['token'] as String?;
        final userJson = combined['user'] as String?;
        if (token == null || userJson == null) {
          try {
            await storage.clear();
          } catch (_) {}
          return null;
        }
        final sesion = await _restoreFromTokenAndUserJson(token, userJson);
        if (sesion != null) {
          return sesion;
        }
        try {
          await storage.clear();
        } catch (_) {}
        return null;
      } catch (_) {
        try {
          await storage.clear();
        } catch (_) {}
        return null;
      }
    }

    // Migración desde claves antiguas
    final token = await storage.readToken();
    final userJson = await storage.readUserJson();

    if (token == null || userJson == null) {
      if (token != null || userJson != null) {
        try {
          await storage.clear();
        } catch (_) {}
      }
      return null;
    }

    final sesion = await _restoreFromTokenAndUserJson(token, userJson);
    if (sesion == null) {
      try {
        await storage.clear();
      } catch (_) {}
      return null;
    }

    // Migrar a formato unificado si es válido
    try {
      await storage.saveSession(token: token, userJson: userJson);
    } catch (_) {
      // Si falla migración, no mantener sesión parcial
      try {
        await storage.clear();
      } catch (_) {}
      return null;
    }
    try {
      await storage.clearLegacySession();
    } catch (_) {
      try {
        await storage.clear();
      } catch (_) {}
      return null;
    }
    return sesion;
  }

  @override
  Future<void> cerrarSesion() async {
    // HU-GEN-02: elimina el token y los datos de sesión del dispositivo.
    await storage.clear();
  }

  Future<Sesion?> _restoreFromTokenAndUserJson(
    String token,
    String userJson,
  ) async {
    // CA HU-AL-01 / HU-GEN-02: token vencido o no decodificable → se descarta.
    if (!_tokenVigente(token)) {
      return null;
    }

    try {
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      if (!_identidadConsistente(token, json)) {
        return null;
      }
      final sesion = _aSesion(json, token);
      return sesion;
    } catch (_) {
      // Registro corrupto
      return null;
    }
  }

  bool _identidadConsistente(String token, Map<String, dynamic> userJson) {
    try {
      final claims = JwtDecoder.decode(token);
      // Intentar comprobar identidad con claims disponibles
      final claimSub = claims['sub'];
      final claimUsername =
          claims['username'] ?? claims['user'] ?? claims['name'];
      final userUsername = userJson['username'];

      // Si hay información para comparar, debe coincidir
      if (claimSub != null && userJson['usuarioId'] != null) {
        final claimSubStr = claimSub.toString();
        final userIdStr = userJson['usuarioId'].toString();
        if (claimSubStr != userIdStr) {
          return false;
        }
      }

      if (claimUsername != null && userUsername != null) {
        if (claimUsername.toString() != userUsername.toString()) {
          return false;
        }
      }

      // Si no hay información suficiente para comprobar identidad,
      // no inventar validación - aceptar solo con otras validaciones
      return true;
    } catch (_) {
      // Si no se puede decodificar para comparar, confiar en otras validaciones
      // pero el token ya fue validado por vigencia
      return true;
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

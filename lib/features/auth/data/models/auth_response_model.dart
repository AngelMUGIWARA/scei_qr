import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/rol.dart';
import '../../../../dominio/sesion.dart';

/// DTO de `POST /auth/login` (contrato verificado en scei_qr_api).
///
/// Respuesta:
/// ```json
/// { "accessToken": "...", "tokenType": "Bearer", "expiresIn": 28800,
///   "user": { "id": 1, "username": "alumno1", "fullName": "...", "rol": "ALUMNO" } }
/// ```
class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.id,
    required this.username,
    required this.fullName,
    required this.rol,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final int id;
  final String username;
  final String fullName;

  /// Rol tal como lo envía la API: `ALUMNO` | `SOPORTE` | `ADMIN`.
  ///
  /// (El campo se llama `rol`; el claim `role` está dentro del JWT.)
  final String rol;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      id: user['id'] as int,
      username: user['username'] as String,
      fullName: user['fullName'] as String,
      rol: user['rol'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
    'user': {'id': id, 'username': username, 'fullName': fullName, 'rol': rol},
  };

  /// Traduce el rol del backend al enum de dominio.
  ///
  /// Esta conversión pertenece a la capa de datos (`lib/dominio/rol.dart`).
  /// Un rol desconocido se trata como respuesta inválida del servidor.
  Rol _aRol() => switch (rol) {
    'ALUMNO' => Rol.alumno,
    'SOPORTE' => Rol.soporteTecnico,
    'ADMIN' => Rol.administrador,
    _ => throw const ServerException(),
  };

  /// Mapea a la entidad de dominio [Sesion].
  ///
  /// `expiraEn` sale del claim `exp` del JWT; si el token no se puede
  /// decodificar se usa `expiresIn` del cuerpo de la respuesta.
  Sesion toSession() => Sesion(
    token: accessToken,
    rol: _aRol(),
    expiraEn: _calculaExpiracion(),
    usuarioId: id,
    username: username,
    nombreCompleto: fullName,
  );

  DateTime _calculaExpiracion() {
    try {
      return JwtDecoder.getExpirationDate(accessToken);
    } catch (_) {
      return DateTime.now().add(Duration(seconds: expiresIn));
    }
  }
}

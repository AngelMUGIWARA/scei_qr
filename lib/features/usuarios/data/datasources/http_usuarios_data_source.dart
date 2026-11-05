import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_tecnico.dart';
import '../models/tecnico_model.dart';
import 'usuarios_remote_data_source.dart';

typedef TokenProvider = Future<String?> Function();

class HttpUsuariosDataSource implements UsuariosRemoteDataSource {
  HttpUsuariosDataSource({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    AppConfig.validateBaseUrl(baseUrl);
  }

  final String baseUrl;
  final TokenProvider tokenProvider;
  final http.Client _client;

  @override
  Future<TecnicoModel> registrarTecnico(SolicitudAltaTecnico solicitud) async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$normalizedBaseUrl/usuarios');

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'username': solicitud.usuarioNormalizado,
              'password': solicitud.contrasenaInicial,
              'fullName': solicitud.nombreNormalizado,
              'correo': solicitud.correoNormalizado,
              'rol': 'SOPORTE',
            }),
          )
          .timeout(AppConfig.requestTimeout);

      return _mapResponse(response);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } catch (_) {
      throw const NetworkException();
    }
  }

  TecnicoModel _mapResponse(http.Response response) {
    final body = _decodeBody(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return TecnicoModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        } catch (_) {
          throw const ServerException();
        }
      case 400:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos del formulario.',
        );
      case 401:
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      case 403:
        throw const ForbiddenException();
      case 409:
        final mensaje =
            _mensaje(body) ?? 'El usuario o el correo ya están registrados.';
        throw ConflictException(mensaje, campo: _campoConflicto(mensaje));
      default:
        throw const ServerException();
    }
  }

  Map<String, dynamic>? _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String? _mensaje(Map<String, dynamic>? body) {
    final message = body?['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List) {
      final partes = message.whereType<String>().toList(growable: false);
      if (partes.isNotEmpty) return partes.join(' ');
    }
    return null;
  }

  String? _campoConflicto(String mensaje) {
    final lower = mensaje.toLowerCase();
    if (lower.contains('correo')) return 'correo';
    if (lower.contains('usuario')) return 'usuario';
    if (lower.contains('matrícula') || lower.contains('matricula')) {
      return 'matricula';
    }
    return null;
  }
}

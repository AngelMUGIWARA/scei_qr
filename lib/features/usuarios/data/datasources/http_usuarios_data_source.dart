import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/edicion_tecnico.dart';
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
    final token = await _requireToken();
    final response = await _send(
      () => _client.post(
        _uri('/usuarios'),
        headers: _headers(token),
        body: jsonEncode({
          'username': solicitud.usuarioNormalizado,
          'password': solicitud.contrasenaInicial,
          'fullName': solicitud.nombreNormalizado,
          'correo': solicitud.correoNormalizado,
          'rol': 'SOPORTE',
        }),
      ),
    );

    return _mapTecnico(response);
  }

  @override
  Future<List<TecnicoModel>> listarTecnicos({
    String? busqueda,
    bool? activo,
  }) async {
    final token = await _requireToken();
    final termino = busqueda?.trim();
    final uri = _uri('/usuarios').replace(
      queryParameters: {
        'rol': 'SOPORTE',
        if (termino != null && termino.isNotEmpty) 'q': termino,
        if (activo != null) 'activo': activo.toString(),
      },
    );

    final response = await _send(
      () => _client.get(uri, headers: _headers(token)),
    );
    _throwIfError(response);

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const ServerException();

      final tecnicos = <TecnicoModel>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) throw const ServerException();
        tecnicos.add(TecnicoModel.fromJson(item));
      }
      return tecnicos;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<TecnicoModel> editarTecnico(
    int id,
    SolicitudEdicionTecnico solicitud,
  ) async {
    final token = await _requireToken();
    final response = await _send(
      () => _client.patch(
        _uri('/usuarios/$id'),
        headers: _headers(token),
        body: jsonEncode({
          'fullName': solicitud.nombreNormalizado,
          'correo': solicitud.correoNormalizado,
          if (solicitud.cambiaContrasena) 'password': solicitud.contrasenaNueva,
        }),
      ),
    );

    return _mapTecnico(response);
  }

  @override
  Future<TecnicoModel> cambiarEstadoTecnico(
    int id, {
    required bool activo,
  }) async {
    final token = await _requireToken();
    final response = await _send(
      () => _client.patch(
        _uri('/usuarios/$id'),
        headers: _headers(token),
        body: jsonEncode({'activo': activo}),
      ),
    );

    return _mapTecnico(response);
  }

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$normalizedBaseUrl$path');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<String> _requireToken() async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    return token;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } catch (_) {
      throw const NetworkException();
    }
  }

  TecnicoModel _mapTecnico(http.Response response) {
    _throwIfError(response);

    try {
      return TecnicoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const ServerException();
    }
  }

  void _throwIfError(http.Response response) {
    final body = _decodeBody(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return;
      case 400:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos del formulario.',
        );
      case 401:
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      case 403:
        throw const ForbiddenException();
      case 404:
        throw const ServerException('El técnico ya no existe.');
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

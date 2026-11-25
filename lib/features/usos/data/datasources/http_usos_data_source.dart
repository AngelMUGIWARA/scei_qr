import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/uso_model.dart';
import 'usos_remote_data_source.dart';

typedef TokenProvider = Future<String?> Function();

class HttpUsosDataSource implements UsosRemoteDataSource {
  HttpUsosDataSource({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    AppConfig.validateBaseUrl(baseUrl);
  }

  final String baseUrl;
  final TokenProvider tokenProvider;
  final http.Client _client;

  String get _normalizedBaseUrl => baseUrl.replaceFirst(RegExp(r'/+$'), '');

  @override
  Future<UsoModel> iniciarUso(String qrToken, {String? idempotencyKey}) async {
    final token = qrToken.trim();
    if (token.isEmpty) {
      throw const ValidationException('El código QR escaneado no es válido.');
    }

    final clave = idempotencyKey?.trim();
    final uri = Uri.parse('$_normalizedBaseUrl/usos');
    final response = await _solicitar(
      'POST',
      uri,
      body: {
        'qrToken': token,
        if (clave != null && clave.isNotEmpty) 'idempotencyKey': clave,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwHttpError(response);
    }

    try {
      return UsoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const ServerException();
    }
  }

  Future<http.Response> _solicitar(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      switch (method) {
        case 'POST':
          return await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(AppConfig.requestTimeout);
        default:
          throw ArgumentError.value(method, 'method', 'Método no soportado');
      }
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

  Never _throwHttpError(http.Response response) {
    final body = _decodeBody(response.body);

    switch (response.statusCode) {
      case 400:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos e inténtalo de nuevo.',
        );
      case 401:
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      case 403:
        throw const ForbiddenException();
      case 404:
        throw NotFoundException(
          _mensaje(body) ?? 'El equipo no existe o está dado de baja.',
        );
      case 409:
        throw ConflictException(
          _mensaje(body) ??
              'Ya tienes un uso activo o el equipo ya está en uso.',
        );
      case 422:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos e inténtalo de nuevo.',
        );
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
}

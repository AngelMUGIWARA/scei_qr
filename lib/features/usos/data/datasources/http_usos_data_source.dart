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
  Future<UsoModel> iniciarUso(String qrToken) async {
    final token = qrToken.trim();
    if (token.isEmpty) {
      throw const ValidationException('El código QR escaneado no es válido.');
    }

    final uri = Uri.parse('$_normalizedBaseUrl/usos');
    final response = await _solicitar('POST', uri, body: {'qrToken': token});

    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwHttpError(response);
    }

    return _mapUso(response);
  }

  /// HU-AL-04: lista de usos del alumno autenticado. El uso activo (si
  /// existe) es el que tiene `estado == "ACTIVO"`.
  @override
  Future<List<UsoModel>> misRegistros() async {
    final uri = Uri.parse('$_normalizedBaseUrl/usos/mis-registros');
    final response = await _solicitar('GET', uri);

    if (response.statusCode != 200) {
      _throwHttpError(response);
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException('Lista inválida');
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Elemento de uso inválido');
            }
            return UsoModel.fromJson(item);
          })
          .toList(growable: false);
    } catch (_) {
      throw const ServerException();
    }
  }

  /// HU-AL-04: el servidor asigna `fin` y devuelve el uso "FINALIZADO".
  @override
  Future<UsoModel> finalizarUso(int usoId) async {
    final uri = Uri.parse('$_normalizedBaseUrl/usos/$usoId/finalizar');
    final response = await _solicitar('PATCH', uri);

    if (response.statusCode != 200) {
      _throwHttpError(
        response,
        mensaje403: 'Solo puedes finalizar tus propios usos.',
        mensaje404: 'El registro de uso no existe.',
        mensaje409: 'El uso ya fue finalizado.',
      );
    }

    return _mapUso(response);
  }

  UsoModel _mapUso(http.Response response) {
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
        case 'GET':
          return await _client
              .get(uri, headers: headers)
              .timeout(AppConfig.requestTimeout);
        case 'PATCH':
          return await _client
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(AppConfig.requestTimeout);
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

  /// Los mensajes por defecto corresponden a HU-AL-03 (iniciar uso); cada
  /// operación puede sustituirlos cuando el código significa otra cosa.
  Never _throwHttpError(
    http.Response response, {
    String? mensaje403,
    String mensaje404 = 'El equipo no existe o está dado de baja.',
    String mensaje409 = 'Ya tienes un uso activo o el equipo ya está en uso.',
  }) {
    final body = _decodeBody(response.body);

    switch (response.statusCode) {
      case 400:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos e inténtalo de nuevo.',
        );
      case 401:
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      case 403:
        throw mensaje403 == null
            ? const ForbiddenException()
            : ForbiddenException(mensaje403);
      case 404:
        throw NotFoundException(_mensaje(body) ?? mensaje404);
      case 409:
        throw ConflictException(_mensaje(body) ?? mensaje409);
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

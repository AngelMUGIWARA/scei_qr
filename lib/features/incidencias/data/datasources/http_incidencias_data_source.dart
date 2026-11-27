import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/incidencia.dart';
import '../models/incidencia_model.dart';
import 'incidencias_remote_data_source.dart';

typedef TokenProvider = Future<String?> Function();

/// Implementación HTTP del datasource de incidencias (HU-AL-06).
///
/// Contrato real (`scei_qr_api`, `app/api/v1/routers/incidencias.py`):
/// - `POST /incidencias` — rol ALUMNO, `multipart/form-data` con los campos
///   `equipoId`, `titulo`, `descripcion` y el archivo opcional `foto`
///   (HU-AL-08, fuera de alcance: no se envía).
/// - Respuesta `incident_public`:
///   `{ id, equipoId, reportadaPorId, atendidaPorId, titulo, descripcion,
///      fotoUrl, estado, solucion, creadaEn, actualizadaEn, equipo,
///      reportadaPor, atendidaPor }`.
///
/// El endpoint no recibe un campo `tipo`: el tipo de problema se manda en
/// `titulo` (único título que acepta el API). El backend tampoco expone
/// `folio`; se deriva del `id` en el modelo (TODO-PENDIENTE).
class HttpIncidenciasDataSource implements IncidenciasRemoteDataSource {
  HttpIncidenciasDataSource({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    AppConfig.validateBaseUrl(baseUrl);
  }

  final String baseUrl;
  final TokenProvider tokenProvider;
  final http.Client _client;

  String get _base => baseUrl.replaceFirst(RegExp(r'/+$'), '');

  @override
  Future<IncidenciaModel> reportarIncidencia({
    required int equipoId,
    required TipoProblema tipo,
    required String descripcion,
  }) async {
    final uri = Uri.parse('$_base/incidencias');
    final response = await _post(
      uri,
      fields: {
        'equipoId': '$equipoId',
        'titulo': tipo.etiqueta,
        'descripcion': descripcion.trim(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwHttpError(response);
    }

    try {
      return IncidenciaModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
        tipo: tipo,
      );
    } catch (_) {
      throw const ServerException();
    }
  }

  Future<http.Response> _post(
    Uri uri, {
    required Map<String, String> fields,
  }) async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    // El endpoint declara Form/File: FastAPI exige multipart/form-data.
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(fields);

    try {
      final streamed = await _client
          .send(request)
          .timeout(AppConfig.requestTimeout);
      return await http.Response.fromStream(streamed)
          .timeout(AppConfig.requestTimeout);
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

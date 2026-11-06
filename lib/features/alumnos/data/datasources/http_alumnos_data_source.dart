import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_alumno.dart';
import '../models/alumno_model.dart';
import 'alumnos_remote_data_source.dart';

typedef TokenProvider = Future<String?> Function();

/// Único punto de mapeo formulario HU-AD-12 → contrato `CreateUsuarioRequest`
/// (`scei_qr_api/app/api/schemas.py`, `extra="forbid"`).
///
/// No existe lógica de mapeo fuera de esta función.
///
/// Mapeo aprobado:
///   nombre               → `fullName`
///   matrícula            → `matricula` (ya normalizada a mayúsculas)
///   correo institucional → `correo` (ya normalizado a minúsculas)
///   usuario              → `username` (por defecto, el correo)
///   contraseña inicial   → `password`
///   rol del alta         → `ALUMNO`
Map<String, dynamic> toCreateAlumnoPayload(SolicitudAltaAlumno solicitud) {
  return {
    'username': solicitud.usuarioNormalizado,
    'password': solicitud.contrasenaInicial,
    'fullName': solicitud.nombre.trim(),
    'correo': solicitud.correoNormalizado,
    'matricula': solicitud.matriculaNormalizada,
    'rol': 'ALUMNO',
    // `activo` NO se envía: el estado inicial "Activo" lo asigna el servidor.
  };
}

class HttpAlumnosDataSource implements AlumnosRemoteDataSource {
  HttpAlumnosDataSource({
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
  Future<AlumnoModel> registrarAlumno(SolicitudAltaAlumno solicitud) async {
    final uri = await _uri('/usuarios');

    try {
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode(toCreateAlumnoPayload(solicitud)),
          )
          .timeout(AppConfig.requestTimeout);

      final model = _mapResponse(response);
      // CA HU-AD-12: la cuenta se crea con el rol Alumno. El estado lo
      // asigna el servidor; aquí solo se verifica.
      if (model.rol != 'ALUMNO' || !model.activo) {
        throw const ServerException();
      }
      return model;
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

  @override
  Future<List<AlumnoModel>> listarAlumnos({
    String? busqueda,
    bool? activo,
  }) async {
    final filtros = <String, String>{'rol': 'ALUMNO'};
    final consulta = busqueda?.trim();
    if (consulta != null && consulta.isNotEmpty) filtros['q'] = consulta;
    if (activo != null) filtros['activo'] = activo ? 'true' : 'false';

    final uri = await _uri('/usuarios', filtros);

    try {
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(AppConfig.requestTimeout);

      return _mapListResponse(response);
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

  @override
  Future<AlumnoModel> cambiarEstado({
    required int id,
    required bool activo,
  }) async {
    final uri = await _uri('/usuarios/$id');

    try {
      final response = await _client
          .patch(
            uri,
            headers: await _headers(),
            // `UpdateUsuarioRequest` admite `activo` parcial: la baja es
            // lógica (no se envían ni se borran los demás datos).
            body: jsonEncode({'activo': activo}),
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

  Future<Uri> _uri(String ruta, [Map<String, String>? filtros]) async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$normalizedBaseUrl$ruta');
    if (filtros == null || filtros.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...filtros});
  }

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  AlumnoModel _mapResponse(http.Response response) {
    final body = _decodeBody(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          return AlumnoModel.fromJson(
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
        // Unicidad de usuario/correo/matrícula: la valida el servidor
        // (UsuariosService.create → ConflictError, HTTP 409).
        final mensaje =
            _mensaje(body) ?? 'El usuario o la matrícula ya están registrados';
        throw ConflictException(mensaje, campo: _campoConflicto(mensaje));
      default:
        throw const ServerException();
    }
  }

  List<AlumnoModel> _mapListResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is! List) throw const ServerException();
          return decoded
              .map((item) => AlumnoModel.fromJson(item as Map<String, dynamic>))
              .toList(growable: false);
        } on ServerException {
          rethrow;
        } catch (_) {
          throw const ServerException();
        }
      case 401:
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      case 403:
        throw const ForbiddenException();
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
    if (lower.contains('matrícula') || lower.contains('matricula')) {
      return 'matricula';
    }
    if (lower.contains('correo')) return 'correo';
    if (lower.contains('usuario')) return 'usuario';
    return null;
  }
}

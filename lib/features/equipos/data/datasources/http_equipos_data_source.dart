import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_equipo.dart';
import '../models/equipo_model.dart';
import 'equipos_remote_data_source.dart';

typedef TokenProvider = Future<String?> Function();

/// Único punto de mapeo formulario HU-AD-04 → contrato `CreateEquipoRequest`
/// (`scei_qr_api/app/api/schemas.py`, `extra="forbid"`).
///
/// No existe lógica de mapeo fuera de esta función.
///
/// Mapeo aprobado:
///   identificador → `codigo`
///   descripción   → `descripcion`
///   ubicación dentro del laboratorio → `ubicacion` (sin concatenar)
Map<String, dynamic> toCreateEquipoPayload(SolicitudAltaEquipo solicitud) {
  return {
    'codigo': solicitud.identificadorNormalizado,
    // TODO-TEMP: `nombre` es obligatorio en el schema pero NO existe en la
    // HU-AD-04. Provisionalmente se envía el identificador; pendiente de
    // aprobación del equipo (no concatenar ni copiar de otro campo sin ella).
    'nombre': solicitud.identificadorNormalizado,
    'descripcion': solicitud.descripcionNormalizada.isEmpty
        ? null
        : solicitud.descripcionNormalizada,
    'ubicacion': solicitud.ubicacionNormalizada,
    // TODO-PENDIENTE: `laboratorio` (HU-AD-04) no tiene campo en el schema y
    // `extra="forbid"` lo rechazaría → NO se envía. Pendiente de decisión.
    //
    // `activo` NO se envía: el estado inicial "Activo" lo asigna el servidor.
  };
}

class HttpEquiposDataSource implements EquiposRemoteDataSource {
  HttpEquiposDataSource({
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
  Future<EquipoModel> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$normalizedBaseUrl/equipos');

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(toCreateEquipoPayload(solicitud)),
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

  EquipoModel _mapResponse(http.Response response) {
    final body = _decodeBody(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        final EquipoModel model;
        try {
          model = EquipoModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        } catch (_) {
          throw const ServerException();
        }
        // CA HU-AD-04: al guardar, el equipo queda con estado "Activo".
        // El estado lo asigna el servidor; aquí solo se verifica.
        if (!model.activo) throw const ServerException();
        return model;
      case 400:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos del formulario.',
        );
      case 401:
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      case 403:
        throw const ForbiddenException();
      case 409:
        // Unicidad del identificador: la valida el servidor
        // (EquiposService.create → ConflictError, HTTP 409).
        final mensaje =
            _mensaje(body) ?? 'El identificador del equipo ya existe';
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
    if (lower.contains('código') || lower.contains('codigo')) {
      return 'identificador';
    }
    return null;
  }
}

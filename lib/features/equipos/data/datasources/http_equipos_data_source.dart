import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/edicion_equipo.dart';
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

/// Mapeo de edición (HU-AD-05) → `UpdateEquipoRequest`.
///
/// Solo incluye campos que el backend actual admite. `nombre` se deriva del
/// código cuando el formulario lo deja vacío, para conservar la compatibilidad
/// con HU-AD-04 y con el schema actual.
Map<String, dynamic> toUpdateEquipoPayload(SolicitudEdicionEquipo solicitud) {
  return {
    'codigo': solicitud.codigoNormalizado,
    'nombre': solicitud.nombreEfectivo,
    'descripcion': solicitud.descripcionNormalizada.isEmpty
        ? null
        : solicitud.descripcionNormalizada,
    'ubicacion': solicitud.ubicacionNormalizada,
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

  String get _normalizedBaseUrl => baseUrl.replaceFirst(RegExp(r'/+$'), '');

  @override
  Future<EquipoModel> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    final uri = Uri.parse('$_normalizedBaseUrl/equipos');
    final response = await _solicitar(
      'POST',
      uri,
      body: toCreateEquipoPayload(solicitud),
    );

    // CA HU-AD-04: al guardar, el equipo queda con estado "Activo".
    // El estado lo asigna el servidor; aquí solo se verifica.
    return _mapEquipoResponse(response, verificarActivo: true);
  }

  @override
  Future<List<EquipoModel>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  }) async {
    final params = <String, String>{};
    final busqueda = q?.trim() ?? '';
    if (busqueda.isNotEmpty) params['q'] = busqueda;
    final ubicacionFiltro = ubicacion?.trim() ?? '';
    if (ubicacionFiltro.isNotEmpty) params['ubicacion'] = ubicacionFiltro;
    if (activo != null) params['activo'] = activo.toString();

    final base = Uri.parse('$_normalizedBaseUrl/equipos');
    final uri = params.isEmpty ? base : base.replace(queryParameters: params);
    final response = await _solicitar('GET', uri);

    if (response.statusCode == 200) {
      return _mapListaResponse(response);
    }
    _throwHttpError(response);
  }

  @override
  Future<EquipoModel> obtenerEquipoPorId(int id) async {
    final uri = Uri.parse('$_normalizedBaseUrl/equipos/$id');
    final response = await _solicitar('GET', uri);
    return _mapEquipoResponse(response);
  }

  @override
  Future<EquipoModel> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async {
    final uri = Uri.parse('$_normalizedBaseUrl/equipos/$id');
    final response = await _solicitar(
      'PATCH',
      uri,
      body: toUpdateEquipoPayload(solicitud),
    );
    return _mapEquipoResponse(response);
  }

  @override
  Future<EquipoModel> cambiarEstadoEquipo(
    int id, {
    required bool activo,
  }) async {
    final uri = Uri.parse('$_normalizedBaseUrl/equipos/$id');
    final response = await _solicitar('PATCH', uri, body: {'activo': activo});
    return _mapEquipoResponse(response);
  }

  /// HU-AD-06: `POST /equipos/{id}/regenerar-qr` (201 con el equipo y el
  /// `qrToken` nuevo; el anterior queda invalidado en el servidor).
  @override
  Future<EquipoModel> regenerarQr(int id) async {
    final uri = Uri.parse('$_normalizedBaseUrl/equipos/$id/regenerar-qr');
    final response = await _solicitar('POST', uri);
    return _mapEquipoResponse(response);
  }

  /// HU-AD-06: `GET /equipos/{id}/qr` → PNG (ADMIN). Devuelve los bytes
  /// tal cual para `Image.memory`.
  @override
  Future<Uint8List> obtenerImagenQr(int id) async {
    final uri = Uri.parse('$_normalizedBaseUrl/equipos/$id/qr');
    final response = await _solicitar('GET', uri);

    if (response.statusCode != 200) {
      _throwHttpError(response);
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) throw const ServerException();
    return bytes;
  }

  /// HU-AL-02: `GET /equipos/qr/{qrToken}` → valida el QR escaneado y
  /// devuelve el equipo (404 si el token no existe o el equipo está
  /// dado de baja).
  @override
  Future<EquipoModel> resolverQr(String qrToken) async {
    final token = qrToken.trim();
    if (token.isEmpty) {
      throw const NotFoundException('El código QR escaneado no es válido.');
    }

    final uri = Uri.parse(
      '$_normalizedBaseUrl/equipos/qr/${Uri.encodeComponent(token)}',
    );
    final response = await _solicitar('GET', uri);
    return _mapEquipoResponse(response);
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
        case 'POST':
          return await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(AppConfig.requestTimeout);
        case 'PATCH':
          return await _client
              .patch(
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

  List<EquipoModel> _mapListaResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw const FormatException('Lista inválida');
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Elemento de equipo inválido');
            }
            return EquipoModel.fromJson(item);
          })
          .toList(growable: false);
    } catch (_) {
      throw const ServerException();
    }
  }

  EquipoModel _mapEquipoResponse(
    http.Response response, {
    bool verificarActivo = false,
  }) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwHttpError(response);
    }

    final EquipoModel model;
    try {
      model = EquipoModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const ServerException();
    }

    if (verificarActivo && !model.activo) throw const ServerException();
    return model;
  }

  Never _throwHttpError(http.Response response) {
    final body = _decodeBody(response.body);

    switch (response.statusCode) {
      case 400:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos del formulario.',
        );
      case 401:
        throw const AuthException('Tu sesión expiró. Inicia sesión de nuevo.');
      case 403:
        throw const ForbiddenException();
      case 404:
        throw NotFoundException(
          _mensaje(body) ?? 'El equipo solicitado no existe.',
        );
      case 409:
        // Unicidad del identificador: la valida el servidor
        // (EquiposService.create → ConflictError, HTTP 409).
        final mensaje =
            _mensaje(body) ?? 'El identificador del equipo ya existe';
        throw ConflictException(mensaje, campo: _campoConflicto(mensaje));
      case 422:
        throw ValidationException(
          _mensaje(body) ?? 'Revisa los datos del formulario.',
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

  String? _campoConflicto(String mensaje) {
    final lower = mensaje.toLowerCase();
    if (lower.contains('código') || lower.contains('codigo')) {
      return 'identificador';
    }
    return null;
  }
}

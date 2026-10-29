import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/auth_response_model.dart';
import 'auth_remote_data_source.dart';

/// Implementación HTTP real del login (HU-AL-01, HU-ST-01, HU-AD-01).
///
/// Contrato: `POST {API_URL}/auth/login` → [AuthResponseModel].
/// Manejo de errores según el CA de HU-AL-01: cualquier fallo de
/// credenciales se traduce en un **mensaje genérico**.
class HttpAuthDataSource implements AuthRemoteDataSource {
  HttpAuthDataSource({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<AuthResponseModel> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
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
      // SocketException, error de parseo, etc.
      throw const NetworkException();
    }
  }

  AuthResponseModel _mapResponse(http.Response response) {
    // 401 (credenciales inválidas / cuenta inactiva) y 400 (DTO inválido)
    // comparten el mismo mensaje genérico: no revelar cuál falló.
    if (response.statusCode == 401 || response.statusCode == 400) {
      throw const AuthException();
    }

    if (response.statusCode != 200) {
      throw const ServerException();
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponseModel.fromJson(decoded);
    } catch (_) {
      throw const ServerException();
    }
  }
}

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/sesion.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';

/// Estados de la sesión (arquitectura-login-sesion §2, patrón Provider).
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Estado global de autenticación (HU-AL-01 / HU-ST-01 / HU-AD-01).
///
/// La UI solo observa este ChangeNotifier; nunca habla con HTTP ni con el
/// almacenamiento directamente. [session] es la misma [Sesion] que consume
/// el guard de acceso de HU-GEN-01.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.loginUseCase,
    required this.restoreSessionUseCase,
  });

  final LoginUseCase loginUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;

  AuthStatus _status = AuthStatus.initial;
  Sesion? _session;
  String? _errorMessage;

  AuthStatus get status => _status;
  Sesion? get session => _session;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Restaura la sesión persistida al arrancar la app.
  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    _session = await restoreSessionUseCase();

    _status = _session != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Intenta iniciar sesión. Devuelve `true` si tuvo éxito.
  ///
  /// Cualquier fallo deja un [errorMessage] **genérico** (CA HU-AL-01).
  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await loginUseCase(username, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _session = null;
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _session = null;
      _status = AuthStatus.error;
      _errorMessage = 'Usuario o contraseña incorrectos';
      notifyListeners();
      return false;
    }
  }

  /// Limpia el mensaje de error sin cambiar el estado (p. ej. al editar el form).
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/tecnico.dart';
import '../../domain/usecases/registrar_tecnico_usecase.dart';

enum RegistroTecnicoStatus { idle, loading, success, error }

class RegistrarTecnicoProvider extends ChangeNotifier {
  RegistrarTecnicoProvider({required this.registrarTecnicoUseCase});

  final RegistrarTecnicoUseCase registrarTecnicoUseCase;

  RegistroTecnicoStatus _status = RegistroTecnicoStatus.idle;
  String? _errorMessage;
  String? _campoError;
  Tecnico? _tecnico;

  RegistroTecnicoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get campoError => _campoError;
  Tecnico? get tecnico => _tecnico;
  bool get isLoading => _status == RegistroTecnicoStatus.loading;
  bool get isSuccess => _status == RegistroTecnicoStatus.success;

  Future<bool> registrar(SolicitudAltaTecnico solicitud) async {
    _status = RegistroTecnicoStatus.loading;
    _errorMessage = null;
    _campoError = null;
    _tecnico = null;
    notifyListeners();

    try {
      _tecnico = await registrarTecnicoUseCase(solicitud);
      _status = RegistroTecnicoStatus.success;
      notifyListeners();
      return true;
    } on ConflictException catch (e) {
      _status = RegistroTecnicoStatus.error;
      _errorMessage = e.message;
      _campoError = e.campo;
      notifyListeners();
      return false;
    } on AppException catch (e) {
      _status = RegistroTecnicoStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _status = RegistroTecnicoStatus.error;
      _errorMessage = 'No se pudo registrar al técnico. Inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null && _campoError == null) return;
    _errorMessage = null;
    _campoError = null;
    if (_status == RegistroTecnicoStatus.error) {
      _status = RegistroTecnicoStatus.idle;
    }
    notifyListeners();
  }

  void reset() {
    _status = RegistroTecnicoStatus.idle;
    _errorMessage = null;
    _campoError = null;
    _tecnico = null;
    notifyListeners();
  }
}

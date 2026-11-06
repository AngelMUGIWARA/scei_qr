import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/usecases/registrar_equipo_usecase.dart';

enum RegistroEquipoStatus { idle, loading, success, error }

class RegistrarEquipoProvider extends ChangeNotifier {
  RegistrarEquipoProvider({required this.registrarEquipoUseCase});

  final RegistrarEquipoUseCase registrarEquipoUseCase;

  RegistroEquipoStatus _status = RegistroEquipoStatus.idle;
  String? _errorMessage;
  String? _campoError;
  Equipo? _equipo;

  RegistroEquipoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get campoError => _campoError;
  Equipo? get equipo => _equipo;
  bool get isLoading => _status == RegistroEquipoStatus.loading;
  bool get isSuccess => _status == RegistroEquipoStatus.success;

  Future<bool> registrar(SolicitudAltaEquipo solicitud) async {
    _status = RegistroEquipoStatus.loading;
    _errorMessage = null;
    _campoError = null;
    _equipo = null;
    notifyListeners();

    try {
      _equipo = await registrarEquipoUseCase(solicitud);
      _status = RegistroEquipoStatus.success;
      notifyListeners();
      return true;
    } on ConflictException catch (e) {
      _status = RegistroEquipoStatus.error;
      _errorMessage = e.message;
      _campoError = e.campo;
      notifyListeners();
      return false;
    } on AppException catch (e) {
      _status = RegistroEquipoStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _status = RegistroEquipoStatus.error;
      _errorMessage = 'No se pudo registrar el equipo. Inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null && _campoError == null) return;
    _errorMessage = null;
    _campoError = null;
    if (_status == RegistroEquipoStatus.error) {
      _status = RegistroEquipoStatus.idle;
    }
    notifyListeners();
  }

  void reset() {
    _status = RegistroEquipoStatus.idle;
    _errorMessage = null;
    _campoError = null;
    _equipo = null;
    notifyListeners();
  }
}

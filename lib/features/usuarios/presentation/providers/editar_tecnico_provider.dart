import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/edicion_tecnico.dart';
import '../../../../dominio/tecnico.dart';
import '../../domain/usecases/editar_tecnico_usecase.dart';

enum EditarTecnicoStatus { idle, loading, success, error }

/// Estado del formulario de edición de un técnico (HU-AD-03).
class EditarTecnicoProvider extends ChangeNotifier {
  EditarTecnicoProvider({required this.editarTecnicoUseCase});

  final EditarTecnicoUseCase editarTecnicoUseCase;

  EditarTecnicoStatus _status = EditarTecnicoStatus.idle;
  String? _errorMessage;
  String? _campoError;
  Tecnico? _tecnico;

  EditarTecnicoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get campoError => _campoError;
  Tecnico? get tecnico => _tecnico;
  bool get isLoading => _status == EditarTecnicoStatus.loading;
  bool get isSuccess => _status == EditarTecnicoStatus.success;

  Future<Tecnico?> editar(int id, SolicitudEdicionTecnico solicitud) async {
    _status = EditarTecnicoStatus.loading;
    _errorMessage = null;
    _campoError = null;
    _tecnico = null;
    notifyListeners();

    try {
      _tecnico = await editarTecnicoUseCase(id, solicitud);
      _status = EditarTecnicoStatus.success;
      notifyListeners();
      return _tecnico;
    } on ConflictException catch (e) {
      _status = EditarTecnicoStatus.error;
      _errorMessage = e.message;
      _campoError = e.campo;
      notifyListeners();
      return null;
    } on AppException catch (e) {
      _status = EditarTecnicoStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _status = EditarTecnicoStatus.error;
      _errorMessage = 'No se pudo actualizar al técnico. Inténtalo de nuevo.';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_errorMessage == null && _campoError == null) return;
    _errorMessage = null;
    _campoError = null;
    if (_status == EditarTecnicoStatus.error) {
      _status = EditarTecnicoStatus.idle;
    }
    notifyListeners();
  }
}

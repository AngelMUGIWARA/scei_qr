import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alta_alumno.dart';
import '../../../../dominio/alumno.dart';
import '../../domain/usecases/registrar_alumno_usecase.dart';

enum RegistroAlumnoStatus { idle, loading, success, error }

class RegistrarAlumnoProvider extends ChangeNotifier {
  RegistrarAlumnoProvider({required this.registrarAlumnoUseCase});

  final RegistrarAlumnoUseCase registrarAlumnoUseCase;

  RegistroAlumnoStatus _status = RegistroAlumnoStatus.idle;
  String? _errorMessage;
  String? _campoError;
  Alumno? _alumno;

  RegistroAlumnoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get campoError => _campoError;
  Alumno? get alumno => _alumno;
  bool get isLoading => _status == RegistroAlumnoStatus.loading;
  bool get isSuccess => _status == RegistroAlumnoStatus.success;

  Future<bool> registrar(SolicitudAltaAlumno solicitud) async {
    _status = RegistroAlumnoStatus.loading;
    _errorMessage = null;
    _campoError = null;
    _alumno = null;
    notifyListeners();

    try {
      _alumno = await registrarAlumnoUseCase(solicitud);
      _status = RegistroAlumnoStatus.success;
      notifyListeners();
      return true;
    } on ConflictException catch (e) {
      _status = RegistroAlumnoStatus.error;
      _errorMessage = e.message;
      _campoError = e.campo;
      notifyListeners();
      return false;
    } on AppException catch (e) {
      _status = RegistroAlumnoStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _status = RegistroAlumnoStatus.error;
      _errorMessage = 'No se pudo registrar al alumno. Inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null && _campoError == null) return;
    _errorMessage = null;
    _campoError = null;
    if (_status == RegistroAlumnoStatus.error) {
      _status = RegistroAlumnoStatus.idle;
    }
    notifyListeners();
  }

  void reset() {
    _status = RegistroAlumnoStatus.idle;
    _errorMessage = null;
    _campoError = null;
    _alumno = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/alumno.dart';
import '../../domain/usecases/cambiar_estado_alumno_usecase.dart';
import '../../domain/usecases/listar_alumnos_usecase.dart';

enum GestionAlumnosStatus { idle, loading, success, error }

class GestionAlumnosProvider extends ChangeNotifier {
  GestionAlumnosProvider({
    required this.listarAlumnosUseCase,
    required this.cambiarEstadoAlumnoUseCase,
  });

  final ListarAlumnosUseCase listarAlumnosUseCase;
  final CambiarEstadoAlumnoUseCase cambiarEstadoAlumnoUseCase;

  GestionAlumnosStatus _status = GestionAlumnosStatus.idle;
  String? _errorMessage;
  List<Alumno> _alumnos = const [];
  String _busqueda = '';
  int? _actualizandoId;

  GestionAlumnosStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Alumno> get alumnos => _alumnos;
  String get busqueda => _busqueda;
  bool get isLoading => _status == GestionAlumnosStatus.loading;

  /// Id de la cuenta cuyo estado se está cambiando (para deshabilitar solo
  /// ese renglón y no toda la lista).
  int? get actualizandoId => _actualizandoId;

  bool estaActualizando(Alumno alumno) => _actualizandoId == alumno.id;

  Future<void> cargar({String? busqueda}) async {
    _busqueda = busqueda ?? _busqueda;
    _status = GestionAlumnosStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sin filtro de estado a propósito: la lista incluye las cuentas dadas
      // de baja para conservar y mostrar el historial (CA HU-AD-12).
      _alumnos = await listarAlumnosUseCase(
        busqueda: _busqueda.isEmpty ? null : _busqueda,
      );
      _status = GestionAlumnosStatus.success;
    } on AppException catch (e) {
      _status = GestionAlumnosStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = GestionAlumnosStatus.error;
      _errorMessage = 'No se pudieron cargar las cuentas. Inténtalo de nuevo.';
    }
    notifyListeners();
  }

  Future<void> buscar(String texto) => cargar(busqueda: texto);

  /// Baja lógica (`activo: false`) o reactivación (`activo: true`).
  /// Devuelve `false` si la operación falló (el mensaje queda en
  /// [errorMessage]).
  Future<bool> cambiarEstado(Alumno alumno, {required bool activo}) async {
    _actualizandoId = alumno.id;
    _errorMessage = null;
    notifyListeners();

    try {
      final actualizado = await cambiarEstadoAlumnoUseCase(
        alumno,
        activo: activo,
      );
      _alumnos = [
        for (final item in _alumnos)
          item.id == actualizado.id ? actualizado : item,
      ];
      _actualizandoId = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar la cuenta. Inténtalo de nuevo.';
    }
    _actualizandoId = null;
    notifyListeners();
    return false;
  }

  void limpiarError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}

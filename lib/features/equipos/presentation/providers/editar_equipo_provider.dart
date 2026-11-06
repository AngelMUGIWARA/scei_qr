import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/edicion_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/usecases/actualizar_equipo_usecase.dart';
import '../../domain/usecases/obtener_equipo_usecase.dart';

enum EditarEquipoStatus { cargando, listo, error, guardando, guardado }

class EditarEquipoProvider extends ChangeNotifier {
  EditarEquipoProvider({
    required this.equipoId,
    required this.obtenerEquipoUseCase,
    required this.actualizarEquipoUseCase,
    Equipo? equipoInicial,
  }) : _equipo = equipoInicial;

  final int equipoId;
  final ObtenerEquipoUseCase obtenerEquipoUseCase;
  final ActualizarEquipoUseCase actualizarEquipoUseCase;

  Equipo? _equipo;
  bool _cargando = false;
  bool _guardando = false;
  String? _errorCarga;
  String? _errorGuardado;
  bool _disposed = false;

  Equipo? get equipo => _equipo;
  bool get cargando => _cargando;
  bool get guardando => _guardando;
  String? get errorCarga => _errorCarga;
  String? get errorGuardado => _errorGuardado;
  bool get listo => _equipo != null;

  Future<void> cargar() async {
    if (_equipo == null) {
      _cargando = true;
    }
    _errorCarga = null;
    _notificar();

    try {
      _equipo = await obtenerEquipoUseCase(equipoId);
    } on AppException catch (error) {
      _errorCarga = error.message;
    } catch (_) {
      _errorCarga = 'No se pudo cargar el equipo. Inténtalo de nuevo.';
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  Future<bool> guardar(SolicitudEdicionEquipo solicitud) async {
    if (_guardando) return false;

    _guardando = true;
    _errorGuardado = null;
    _notificar();

    try {
      _equipo = await actualizarEquipoUseCase(equipoId, solicitud);
      return true;
    } on AppException catch (error) {
      _errorGuardado = error.message;
      return false;
    } catch (_) {
      _errorGuardado = 'No se pudo actualizar el equipo. Inténtalo de nuevo.';
      return false;
    } finally {
      _guardando = false;
      _notificar();
    }
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

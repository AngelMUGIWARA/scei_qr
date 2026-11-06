import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/usecases/cambiar_estado_equipo_usecase.dart';
import '../../domain/usecases/listar_equipos_usecase.dart';

enum ListarEquiposStatus { inicial, cargando, cargado, error }

class ListarEquiposProvider extends ChangeNotifier {
  ListarEquiposProvider({
    required this.listarEquiposUseCase,
    required this.cambiarEstadoEquipoUseCase,
    this.debounce = const Duration(milliseconds: 350),
  });

  final ListarEquiposUseCase listarEquiposUseCase;
  final CambiarEstadoEquipoUseCase cambiarEstadoEquipoUseCase;
  final Duration debounce;

  ListarEquiposStatus _status = ListarEquiposStatus.inicial;
  List<Equipo> _equipos = const [];
  String? _errorMessage;
  String _busqueda = '';
  String _ubicacion = '';
  bool? _activo;
  bool _refrescando = false;
  int? _procesandoId;
  String? _mensajeAccion;
  String? _errorAccion;
  Timer? _debounceTimer;
  int _peticionActual = 0;
  bool _disposed = false;

  ListarEquiposStatus get status => _status;
  List<Equipo> get equipos => _equipos;
  String? get errorMessage => _errorMessage;
  String get busqueda => _busqueda;
  String get ubicacion => _ubicacion;
  bool? get activo => _activo;
  bool get refrescando => _refrescando;
  int? get procesandoId => _procesandoId;
  String? get mensajeAccion => _mensajeAccion;
  String? get errorAccion => _errorAccion;
  bool get cargando => _status == ListarEquiposStatus.cargando;
  bool get hayError => _status == ListarEquiposStatus.error;
  bool get hayFiltros =>
      _busqueda.trim().isNotEmpty ||
      _ubicacion.trim().isNotEmpty ||
      _activo != null;
  bool get vacio => _status == ListarEquiposStatus.cargado && _equipos.isEmpty;

  Future<void> cargar({bool mostrarCarga = true}) async {
    final peticion = ++_peticionActual;
    if (mostrarCarga) {
      _status = ListarEquiposStatus.cargando;
    } else {
      _refrescando = true;
    }
    _errorMessage = null;
    _notificar();

    try {
      final equipos = await listarEquiposUseCase(
        q: _busqueda,
        ubicacion: _ubicacion,
        activo: _activo,
      );
      if (peticion != _peticionActual) return;
      _equipos = equipos;
      _status = ListarEquiposStatus.cargado;
    } on AppException catch (error) {
      if (peticion != _peticionActual) return;
      _errorMessage = error.message;
      _status = ListarEquiposStatus.error;
    } catch (_) {
      if (peticion != _peticionActual) return;
      _errorMessage = 'No se pudieron cargar los equipos. Inténtalo de nuevo.';
      _status = ListarEquiposStatus.error;
    } finally {
      if (peticion == _peticionActual) {
        _refrescando = false;
        _notificar();
      }
    }
  }

  void actualizarBusqueda(String value) {
    if (value == _busqueda) return;
    _busqueda = value;
    _programarCarga();
  }

  void actualizarUbicacion(String value) {
    if (value == _ubicacion) return;
    _ubicacion = value;
    _programarCarga();
  }

  void actualizarEstado(bool? value) {
    if (value == _activo) return;
    _activo = value;
    _debounceTimer?.cancel();
    cargar();
  }

  void limpiarFiltros() {
    if (!hayFiltros) return;
    _busqueda = '';
    _ubicacion = '';
    _activo = null;
    _debounceTimer?.cancel();
    cargar();
  }

  Future<bool> cambiarEstado(Equipo equipo) async {
    if (_procesandoId != null) return false;

    _procesandoId = equipo.id;
    _mensajeAccion = null;
    _errorAccion = null;
    _notificar();

    try {
      final actualizado = await cambiarEstadoEquipoUseCase(
        equipo.id,
        activo: !equipo.activo,
      );
      _mensajeAccion = actualizado.activo
          ? 'Equipo ${actualizado.identificador} reactivado.'
          : 'Equipo ${actualizado.identificador} dado de baja.';
      await cargar(mostrarCarga: false);
      return true;
    } on AppException catch (error) {
      _errorAccion = error.message;
      return false;
    } catch (_) {
      _errorAccion =
          'No se pudo cambiar el estado del equipo. Inténtalo de nuevo.';
      return false;
    } finally {
      _procesandoId = null;
      _notificar();
    }
  }

  void limpiarMensajes() {
    if (_mensajeAccion == null && _errorAccion == null) return;
    _mensajeAccion = null;
    _errorAccion = null;
    _notificar();
  }

  void _programarCarga() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      if (!_disposed) cargar();
    });
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}

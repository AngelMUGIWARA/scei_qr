import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/tecnico.dart';
import '../../domain/usecases/cambiar_estado_tecnico_usecase.dart';
import '../../domain/usecases/listar_tecnicos_usecase.dart';

enum TecnicosStatus { idle, loading, success, error }

enum FiltroEstadoTecnicos {
  todos('Todos', null),
  activos('Activos', true),
  inactivos('Inactivos', false);

  const FiltroEstadoTecnicos(this.etiqueta, this.activo);

  final String etiqueta;
  final bool? activo;
}

/// Estado del listado de técnicos y de la activación/desactivación de
/// cuentas (HU-AD-03).
class AdministrarTecnicosProvider extends ChangeNotifier {
  AdministrarTecnicosProvider({
    required this.listarTecnicosUseCase,
    required this.cambiarEstadoTecnicoUseCase,
  });

  final ListarTecnicosUseCase listarTecnicosUseCase;
  final CambiarEstadoTecnicoUseCase cambiarEstadoTecnicoUseCase;

  TecnicosStatus _status = TecnicosStatus.idle;
  List<Tecnico> _tecnicos = const [];
  String _busqueda = '';
  FiltroEstadoTecnicos _filtro = FiltroEstadoTecnicos.todos;
  String? _errorMessage;
  int? _cambiandoEstadoId;
  int _cargaId = 0;

  TecnicosStatus get status => _status;
  List<Tecnico> get tecnicos => List.unmodifiable(_tecnicos);
  String get busqueda => _busqueda;
  FiltroEstadoTecnicos get filtro => _filtro;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == TecnicosStatus.loading;
  bool get hasError => _status == TecnicosStatus.error;
  bool get isEmpty => _tecnicos.isEmpty;

  bool isCambiandoEstado(Tecnico tecnico) => _cambiandoEstadoId == tecnico.id;

  bool get hayCambioEnCurso => _cambiandoEstadoId != null;

  Future<void> cargar() async {
    final cargaId = ++_cargaId;
    _status = TecnicosStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final tecnicos = await listarTecnicosUseCase(
        busqueda: _busqueda.isEmpty ? null : _busqueda,
        activo: _filtro.activo,
      );
      if (cargaId != _cargaId) return;
      _tecnicos = tecnicos;
      _status = TecnicosStatus.success;
    } on AppException catch (e) {
      if (cargaId != _cargaId) return;
      _status = TecnicosStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      if (cargaId != _cargaId) return;
      _status = TecnicosStatus.error;
      _errorMessage = 'No se pudieron cargar los técnicos. Inténtalo de nuevo.';
    }
    notifyListeners();
  }

  Future<void> buscar(String valor) async {
    _busqueda = valor.trim();
    await cargar();
  }

  Future<void> cambiarFiltro(FiltroEstadoTecnicos filtro) async {
    if (_filtro == filtro) return;
    _filtro = filtro;
    await cargar();
  }

  bool _coincideConFiltro(Tecnico tecnico) =>
      _filtro.activo == null || tecnico.activo == _filtro.activo;

  /// Activa o desactiva una cuenta. Devuelve `true` si el backend confirmó
  /// el cambio.
  Future<bool> cambiarEstado(Tecnico tecnico, {required bool activo}) async {
    if (hayCambioEnCurso) return false;

    _cambiandoEstadoId = tecnico.id;
    _errorMessage = null;
    notifyListeners();

    try {
      final actualizado = await cambiarEstadoTecnicoUseCase(
        tecnico.id,
        activo: activo,
      );

      final visibles = <Tecnico>[];
      for (final item in _tecnicos) {
        if (item.id == actualizado.id) {
          if (_coincideConFiltro(actualizado)) visibles.add(actualizado);
        } else {
          visibles.add(item);
        }
      }
      _tecnicos = visibles;
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar la cuenta. Inténtalo de nuevo.';
      return false;
    } finally {
      _cambiandoEstadoId = null;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    if (_status == TecnicosStatus.error) {
      _status = _tecnicos.isEmpty
          ? TecnicosStatus.idle
          : TecnicosStatus.success;
    }
    notifyListeners();
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/cola_usos_pendientes_repository.dart';
import '../../domain/usecases/sincronizar_usos_pendientes_usecase.dart';

/// Mantiene sincronizados los usos pendientes: al arrancar y cada vez que el
/// dispositivo recupera conexión (HU-AL-03).
class SincronizacionUsosProvider extends ChangeNotifier {
  SincronizacionUsosProvider({
    required this.sincronizarUseCase,
    required this.cola,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  final SincronizarUsosPendientesUseCase sincronizarUseCase;
  final ColaUsosPendientesRepository cola;
  final Connectivity connectivity;

  StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  int _pendientes = 0;
  bool _sincronizando = false;
  bool _disposed = false;

  int get pendientes => _pendientes;
  bool get sincronizando => _sincronizando;

  Future<void> iniciar() async {
    if (_suscripcion == null) {
      try {
        _suscripcion = connectivity.onConnectivityChanged.listen(
          _alCambiarConectividad,
          onError: (_) {},
        );
      } catch (_) {
        // Sin plugin de conectividad (tests/escritorio): el sync inicial basta.
      }
    }
    await actualizarPendientes();
    await sincronizar();
  }

  void _alCambiarConectividad(List<ConnectivityResult> resultados) {
    final hayConexion = resultados.any(
      (resultado) => resultado != ConnectivityResult.none,
    );
    if (hayConexion) {
      unawaited(sincronizar());
    }
  }

  Future<void> actualizarPendientes() async {
    _pendientes = await cola.contar();
    _notificar();
  }

  Future<void> sincronizar() async {
    if (_sincronizando) return;

    _sincronizando = true;
    _notificar();

    try {
      final resultado = await sincronizarUseCase();
      _pendientes = resultado.pendientesRestantes;
    } catch (_) {
      _pendientes = await cola.contar();
    } finally {
      _sincronizando = false;
      _notificar();
    }
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _suscripcion?.cancel();
    super.dispose();
  }
}

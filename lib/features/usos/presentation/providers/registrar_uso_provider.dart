import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/equipo.dart';
import '../../../../dominio/uso.dart';
import '../../domain/usecases/registrar_uso_usecase.dart';

enum RegistroUsoStatus {
  confirmando,
  registrando,
  registrado,

  /// Sin conexión: el registro quedó guardado localmente para sincronizarse.
  pendiente,
  error,
}

class RegistrarUsoProvider extends ChangeNotifier {
  RegistrarUsoProvider({
    required this.registrarUsoUseCase,
    required this.equipo,
    required this.qrToken,
  });

  final RegistrarUsoUseCase registrarUsoUseCase;
  final Equipo equipo;
  final String qrToken;

  RegistroUsoStatus _status = RegistroUsoStatus.confirmando;
  Uso? _uso;
  String? _error;
  bool _reintentable = false;
  bool _enviando = false;
  bool _disposed = false;

  RegistroUsoStatus get status => _status;
  Uso? get uso => _uso;
  String? get error => _error;
  bool get reintentable => _reintentable;
  bool get enviando => _enviando;

  Future<void> confirmar() async {
    if (_enviando) return;

    _enviando = true;
    _status = RegistroUsoStatus.registrando;
    _error = null;
    _reintentable = false;
    _notificar();

    try {
      final resultado = await registrarUsoUseCase(
        qrToken: qrToken,
        equipo: equipo,
      );

      if (resultado.esPendiente) {
        _uso = null;
        _status = RegistroUsoStatus.pendiente;
      } else {
        _uso = resultado.uso;
        _status = RegistroUsoStatus.registrado;
      }
    } on NetworkException catch (error) {
      _error = error.message;
      _reintentable = true;
      _status = RegistroUsoStatus.error;
    } on ServerException catch (error) {
      _error = error.message;
      _reintentable = true;
      _status = RegistroUsoStatus.error;
    } on AppException catch (error) {
      _error = error.message;
      _status = RegistroUsoStatus.error;
    } catch (_) {
      _error = 'No se pudo registrar el uso. Inténtalo de nuevo.';
      _reintentable = true;
      _status = RegistroUsoStatus.error;
    } finally {
      _enviando = false;
      _notificar();
    }
  }

  Future<void> reintentar() => confirmar();

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

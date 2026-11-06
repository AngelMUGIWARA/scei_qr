import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/equipo.dart';
import '../../../equipos/domain/usecases/validar_qr_usecase.dart';
import '../../domain/permiso_camara.dart';

enum EscaneoStatus {
  /// Pidiendo permiso de cámara la primera vez.
  solicitandoPermiso,

  /// Permiso concedido, cámara activa esperando un QR.
  escaneando,

  /// QR leído, validándolo contra el backend.
  validando,

  /// QR válido: equipo identificado.
  equipoEncontrado,

  /// QR inexistente o equipo dado de baja (404 del backend).
  errorQr,

  /// Permiso de cámara denegado (explicar cómo habilitarlo).
  permisoDenegado,
}

/// HU-AL-02: controla el flujo de escaneo → validación → equipo.
class EscaneoProvider extends ChangeNotifier {
  EscaneoProvider({
    required this.validarQrUseCase,
    required this.permisoCamara,
  });

  final ValidarQrUseCase validarQrUseCase;
  final PermisoCamara permisoCamara;

  EscaneoStatus _status = EscaneoStatus.solicitandoPermiso;
  Equipo? _equipo;
  String? _errorQr;
  bool _procesando = false;
  bool _disposed = false;

  EscaneoStatus get status => _status;
  Equipo? get equipo => _equipo;
  String? get errorQr => _errorQr;
  bool get procesando => _procesando;

  /// Inicia el flujo: verifica/solicita el permiso de cámara.
  Future<void> iniciar() async {
    _status = EscaneoStatus.solicitandoPermiso;
    _errorQr = null;
    _equipo = null;
    _notificar();

    final concedido = await permisoCamara.estaConcedido();
    if (!concedido) {
      final otorgado = await permisoCamara.solicitar();
      if (!otorgado) {
        _status = EscaneoStatus.permisoDenegado;
        _notificar();
        return;
      }
    }

    _status = EscaneoStatus.escaneando;
    _notificar();
  }

  /// CA: el permiso denegado lleva a explicar cómo habilitarlo.
  Future<void> abrirAjustes() async {
    await permisoCamara.abrirAjustes();
    // Al volver de ajustes se revalide el permiso.
    await iniciar();
  }

  /// Vuelve a la cámara tras un QR inválido (CA: permite reintentar).
  void reintentar() {
    _status = EscaneoStatus.escaneando;
    _errorQr = null;
    _equipo = null;
    _notificar();
  }

  /// Procesa el QR leído por la cámara. Ignora lecturas duplicadas o
  /// fuera de fase (la cámara puede emitir varios frames seguidos).
  Future<void> procesarQr(String valor) async {
    if (_procesando) return;
    if (_status != EscaneoStatus.escaneando) return;

    final token = valor.trim();
    if (token.isEmpty) return;

    _procesando = true;
    _status = EscaneoStatus.validando;
    _errorQr = null;
    _notificar();

    try {
      _equipo = await validarQrUseCase(token);
      _status = EscaneoStatus.equipoEncontrado;
    } on NotFoundException catch (error) {
      // 404: QR no pertenece al sistema o equipo dado de baja. El mensaje
      // del backend cubre ambos casos y se muestra con opción de reintentar.
      _errorQr = error.message;
      _status = EscaneoStatus.errorQr;
    } on AppException catch (error) {
      _errorQr = error.message;
      _status = EscaneoStatus.errorQr;
    } catch (_) {
      _errorQr = 'No se pudo validar el código. Inténtalo de nuevo.';
      _status = EscaneoStatus.errorQr;
    } finally {
      _procesando = false;
      _notificar();
    }
  }

  /// Reinicia todo el flujo (por ejemplo, al salir y volver a entrar).
  Future<void> reiniciar() => iniciar();

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

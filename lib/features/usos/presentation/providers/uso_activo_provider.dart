import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/uso.dart';
import '../../domain/usecases/finalizar_uso_usecase.dart';
import '../../domain/usecases/obtener_uso_activo_usecase.dart';

enum UsoActivoStatus {
  /// Consultando `GET /usos/mis-registros`.
  cargando,

  /// El alumno no tiene un uso activo: no se muestra "Finalizar uso".
  sinUso,

  /// Hay un uso activo: se muestra "Finalizar uso".
  activo,

  /// Enviando `PATCH /usos/{id}/finalizar`.
  finalizando,

  /// Uso finalizado: se muestra el resumen.
  finalizado,

  /// No se pudo consultar el uso activo.
  error,
}

/// HU-AL-04: estado del uso activo del alumno y su finalización.
class UsoActivoProvider extends ChangeNotifier {
  UsoActivoProvider({
    required this.obtenerUsoActivoUseCase,
    required this.finalizarUsoUseCase,
  });

  final ObtenerUsoActivoUseCase obtenerUsoActivoUseCase;
  final FinalizarUsoUseCase finalizarUsoUseCase;

  UsoActivoStatus _status = UsoActivoStatus.cargando;
  Uso? _usoActivo;
  Uso? _usoFinalizado;
  String? _mensaje;
  bool _disposed = false;

  UsoActivoStatus get status => _status;
  Uso? get usoActivo => _usoActivo;
  Uso? get usoFinalizado => _usoFinalizado;

  /// Mensaje de error (o aviso) para mostrar junto al estado actual.
  String? get mensaje => _mensaje;

  /// CA1: el botón solo existe mientras haya un registro activo.
  bool get muestraBotonFinalizar =>
      _usoActivo != null &&
      (_status == UsoActivoStatus.activo ||
          _status == UsoActivoStatus.finalizando);

  Future<void> cargar() async {
    if (_status == UsoActivoStatus.finalizando) return;

    _status = UsoActivoStatus.cargando;
    _mensaje = null;
    _usoFinalizado = null;
    _notificar();

    try {
      _usoActivo = await obtenerUsoActivoUseCase();
      _status = _usoActivo == null
          ? UsoActivoStatus.sinUso
          : UsoActivoStatus.activo;
    } on AppException catch (error) {
      _usoActivo = null;
      _mensaje = error.message;
      _status = UsoActivoStatus.error;
    } catch (_) {
      _usoActivo = null;
      _mensaje = 'No se pudo consultar tu uso activo. Inténtalo de nuevo.';
      _status = UsoActivoStatus.error;
    } finally {
      _notificar();
    }
  }

  Future<void> finalizar() async {
    final uso = _usoActivo;
    if (uso == null || _status != UsoActivoStatus.activo) return;

    _status = UsoActivoStatus.finalizando;
    _mensaje = null;
    _notificar();

    try {
      _usoFinalizado = await finalizarUsoUseCase(uso.id);
      _usoActivo = null;
      _status = UsoActivoStatus.finalizado;
    } on ConflictException catch (error) {
      // 409: ya estaba finalizado en el servidor; ya no hay uso activo.
      _sinUsoConMensaje(error.message);
    } on NotFoundException catch (error) {
      _sinUsoConMensaje(error.message);
    } on ForbiddenException catch (error) {
      _sinUsoConMensaje(error.message);
    } on AppException catch (error) {
      // Sin conexión, error del servidor o sesión expirada: se conserva el
      // uso activo en pantalla para poder volver a intentarlo.
      _mensaje = error.message;
      _status = UsoActivoStatus.activo;
    } catch (_) {
      _mensaje = 'No se pudo finalizar el uso. Inténtalo de nuevo.';
      _status = UsoActivoStatus.activo;
    } finally {
      _notificar();
    }
  }

  void _sinUsoConMensaje(String mensaje) {
    _usoActivo = null;
    _mensaje = mensaje;
    _status = UsoActivoStatus.sinUso;
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

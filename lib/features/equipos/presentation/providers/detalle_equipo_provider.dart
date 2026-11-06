import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/usecases/obtener_equipo_usecase.dart';
import '../../domain/usecases/obtener_imagen_qr_usecase.dart';
import '../../domain/usecases/regenerar_qr_usecase.dart';

enum DetalleEquipoStatus { inicial, cargando, listo, error }

class DetalleEquipoProvider extends ChangeNotifier {
  DetalleEquipoProvider({
    required this.equipoId,
    required this.obtenerEquipoUseCase,
    required this.obtenerImagenQrUseCase,
    required this.regenerarQrUseCase,
    Equipo? equipoInicial,
  }) : _equipo = equipoInicial;

  final int equipoId;
  final ObtenerEquipoUseCase obtenerEquipoUseCase;
  final ObtenerImagenQrUseCase obtenerImagenQrUseCase;
  final RegenerarQrUseCase regenerarQrUseCase;

  Equipo? _equipo;
  Uint8List? _qrBytes;
  bool _cargandoEquipo = false;
  bool _cargandoQr = false;
  bool _regenerando = false;
  String? _errorEquipo;
  String? _errorQr;
  String? _errorAccion;
  bool _qrInvalidado = false;
  bool _disposed = false;

  Equipo? get equipo => _equipo;
  Uint8List? get qrBytes => _qrBytes;
  bool get cargandoEquipo => _cargandoEquipo;
  bool get cargandoQr => _cargandoQr;
  bool get regenerando => _regenerando;
  String? get errorEquipo => _errorEquipo;
  String? get errorQr => _errorQr;
  String? get errorAccion => _errorAccion;

  /// CA HU-AD-06: tras regenerar se informa al administrador que el QR
  /// anterior dejó de ser válido.
  bool get qrInvalidado => _qrInvalidado;

  bool get listo => _equipo != null;

  /// Carga el equipo y, si existe, su imagen QR.
  Future<void> cargar() async {
    if (_equipo == null) {
      _cargandoEquipo = true;
    }
    _errorEquipo = null;
    _notificar();

    try {
      _equipo = await obtenerEquipoUseCase(equipoId);
      _errorEquipo = null;
    } on AppException catch (error) {
      _errorEquipo = error.message;
    } catch (_) {
      _errorEquipo = 'No se pudo cargar el equipo. Inténtalo de nuevo.';
    } finally {
      _cargandoEquipo = false;
      _notificar();
    }

    if (_equipo != null) {
      await cargarQr();
    }
  }

  /// Descarga el PNG del QR. Un fallo no bloquea el detalle: solo se
  /// muestra el error con opción de reintentar.
  Future<void> cargarQr() async {
    if (_cargandoQr) return;
    _cargandoQr = true;
    _errorQr = null;
    _notificar();

    try {
      _qrBytes = await obtenerImagenQrUseCase(equipoId);
    } on AppException catch (error) {
      _errorQr = error.message;
      _qrBytes = null;
    } catch (_) {
      _errorQr = 'No se pudo cargar el código QR. Inténtalo de nuevo.';
      _qrBytes = null;
    } finally {
      _cargandoQr = false;
      _notificar();
    }
  }

  /// Regenera el QR: el servidor invalida el anterior. Devuelve `true` si
  /// tuvo éxito para que la UI muestre el aviso de invalidación.
  Future<bool> regenerarQr() async {
    if (_regenerando) return false;
    _regenerando = true;
    _errorAccion = null;
    _qrInvalidado = false;
    _notificar();

    try {
      _equipo = await regenerarQrUseCase(equipoId);
      _qrInvalidado = true;
      // El PNG anterior corresponde al token invalidado: se descarga el
      // nuevo antes de avisar.
      await cargarQr();
      return true;
    } on AppException catch (error) {
      _errorAccion = error.message;
      return false;
    } catch (_) {
      _errorAccion = 'No se pudo regenerar el QR. Inténtalo de nuevo.';
      return false;
    } finally {
      _regenerando = false;
      _notificar();
    }
  }

  void limpiarMensajes() {
    _errorAccion = null;
    _qrInvalidado = false;
    _notificar();
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

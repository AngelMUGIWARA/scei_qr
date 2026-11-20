import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/printing/impresion_service.dart';
import '../../../../core/utils/slug.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/usecases/descargar_etiqueta_qr_usecase.dart';
import '../../domain/usecases/descargar_etiquetas_lote_usecase.dart';
import '../../domain/usecases/listar_equipos_usecase.dart';

/// HU-AD-07: estado de la pantalla de códigos QR y etiquetas.
class GestionCodigosQrProvider extends ChangeNotifier {
  GestionCodigosQrProvider({
    required this.listarEquiposUseCase,
    required this.descargarEtiquetaQrUseCase,
    required this.descargarEtiquetasLoteUseCase,
    required this.impresionService,
  });

  final ListarEquiposUseCase listarEquiposUseCase;
  final DescargarEtiquetaQrUseCase descargarEtiquetaQrUseCase;
  final DescargarEtiquetasLoteUseCase descargarEtiquetasLoteUseCase;
  final ImpresionService impresionService;

  List<Equipo> _equipos = const [];
  bool _cargando = false;
  bool _procesandoLote = false;
  int? _procesandoId;
  String? _error;
  String? _errorAccion;
  String? _mensajeAccion;
  String _laboratorio = '';
  String _ubicacion = '';
  bool _disposed = false;

  List<Equipo> get equipos => _equipos;
  bool get cargando => _cargando;
  bool get procesandoLote => _procesandoLote;
  int? get procesandoId => _procesandoId;
  String? get error => _error;
  String? get errorAccion => _errorAccion;
  String? get mensajeAccion => _mensajeAccion;
  String get laboratorio => _laboratorio;
  String get ubicacion => _ubicacion;
  bool get hayFiltros =>
      _laboratorio.trim().isNotEmpty || _ubicacion.trim().isNotEmpty;

  Future<void> cargar({bool mostrarCarga = true}) async {
    if (_cargando) return;
    _cargando = mostrarCarga;
    _error = null;
    _notificar();

    try {
      _equipos = await listarEquiposUseCase(
        laboratorio: _laboratorio,
        ubicacion: _ubicacion,
        activo: true,
      );
      _error = null;
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudieron cargar los equipos. Inténtalo de nuevo.';
    } finally {
      _cargando = false;
      _notificar();
    }
  }

  void actualizarFiltros({
    required String laboratorio,
    required String ubicacion,
  }) {
    _laboratorio = laboratorio.trim();
    _ubicacion = ubicacion.trim();
    cargar(mostrarCarga: false);
  }

  void limpiarFiltros() {
    _laboratorio = '';
    _ubicacion = '';
    cargar(mostrarCarga: false);
  }

  /// Descarga o imprime las etiquetas de todos los equipos del filtro actual.
  Future<bool> procesarLote({required bool imprimir}) async {
    if (_procesandoLote || _equipos.isEmpty) return false;
    _procesandoLote = true;
    _errorAccion = null;
    _mensajeAccion = null;
    _notificar();

    try {
      final pdf = await descargarEtiquetasLoteUseCase(
        laboratorio: _laboratorio,
        ubicacion: _ubicacion,
        activo: true,
      );
      final nombre =
          'etiquetas-${slugArchivo(_laboratorio.isNotEmpty ? _laboratorio : _ubicacion)}.pdf';
      await _entregar(pdf, nombre: nombre, imprimir: imprimir);
      _mensajeAccion = imprimir
          ? 'Etiquetas enviadas a imprimir.'
          : 'Etiquetas listas para guardar o compartir.';
      return true;
    } on AppException catch (e) {
      _errorAccion = e.message;
      return false;
    } catch (_) {
      _errorAccion = imprimir
          ? 'No se pudieron imprimir las etiquetas.'
          : 'No se pudieron descargar las etiquetas.';
      return false;
    } finally {
      _procesandoLote = false;
      _notificar();
    }
  }

  /// Descarga o imprime la etiqueta individual de un equipo.
  Future<bool> procesarEquipo(Equipo equipo, {required bool imprimir}) async {
    if (_procesandoId != null) return false;
    _procesandoId = equipo.id;
    _errorAccion = null;
    _mensajeAccion = null;
    _notificar();

    try {
      final pdf = await descargarEtiquetaQrUseCase(equipo.id);
      await _entregar(
        pdf,
        nombre: 'etiqueta-${slugArchivo(equipo.identificador)}.pdf',
        imprimir: imprimir,
      );
      _mensajeAccion = imprimir
          ? 'Etiqueta enviada a imprimir.'
          : 'Etiqueta lista para guardar o compartir.';
      return true;
    } on AppException catch (e) {
      _errorAccion = e.message;
      return false;
    } catch (_) {
      _errorAccion = imprimir
          ? 'No se pudo imprimir la etiqueta.'
          : 'No se pudo descargar la etiqueta.';
      return false;
    } finally {
      _procesandoId = null;
      _notificar();
    }
  }

  Future<void> _entregar(
    Uint8List pdf, {
    required String nombre,
    required bool imprimir,
  }) {
    if (imprimir) return impresionService.imprimir(pdf, nombre: nombre);
    return impresionService.descargar(pdf, nombre: nombre);
  }

  void limpiarMensajes() {
    _errorAccion = null;
    _mensajeAccion = null;
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

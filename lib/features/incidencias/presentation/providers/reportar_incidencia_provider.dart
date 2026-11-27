import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../dominio/equipo.dart';
import '../../../../dominio/incidencia.dart';
import '../../../../dominio/nueva_incidencia.dart';
import '../../domain/usecases/reportar_incidencia_usecase.dart';

enum ReporteIncidenciaStatus {
  /// El formulario está visible y editable.
  formulario,

  /// La petición está en vuelo.
  enviando,

  /// El backend confirmó la creación; se muestra el folio.
  enviado,

  /// Ocurrió un error al enviar.
  error,
}

/// HU-AL-06: controla el formulario de reporte y el envío al backend.
///
/// Responsabilidades:
/// - Mantener el estado del formulario (tipo y descripción).
/// - Validar campos obligatorios antes de enviar (CA HU-AL-06).
/// - Invocar el caso de uso y exponer el resultado (folio) o el error.
class ReportarIncidenciaProvider extends ChangeNotifier {
  ReportarIncidenciaProvider(this._useCase, this._equipo);

  /// Longitud máxima de la descripción (CA HU-AL-06).
  static const int maxDescripcion = 500;

  final ReportarIncidenciaUseCase _useCase;
  final Equipo _equipo;

  ReporteIncidenciaStatus _status = ReporteIncidenciaStatus.formulario;

  /// El tipo de problema es obligatorio y **no** viene preseleccionado:
  /// el alumno debe elegirlo (CA HU-AL-06).
  TipoProblema? _tipo;
  String _descripcion = '';
  Incidencia? _incidencia;
  String? _error;
  bool _reintentable = false;
  bool _disposed = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  ReporteIncidenciaStatus get status => _status;
  TipoProblema? get tipo => _tipo;
  String get descripcion => _descripcion;
  Incidencia? get incidencia => _incidencia;
  String? get error => _error;
  bool get reintentable => _reintentable;
  Equipo get equipo => _equipo;

  /// `true` cuando la descripción tiene contenido (el otro campo
  /// obligatorio, el tipo, se valida al intentar enviar). El botón se
  /// habilita solo con esto (CA HU-AL-06).
  bool get descripcionLista => _descripcion.trim().isNotEmpty;

  // ── Acciones del formulario ───────────────────────────────────────────────

  void cambiarTipo(TipoProblema valor) {
    if (_status != ReporteIncidenciaStatus.formulario) return;
    _tipo = valor;
    _notificar();
  }

  void cambiarDescripcion(String valor) {
    if (_status != ReporteIncidenciaStatus.formulario) return;
    _descripcion = valor;
    _notificar();
  }

  /// Devuelve el mensaje de error de descripción solo cuando el campo
  /// fue tocado y está vacío (usado por el TextField).
  String? validarDescripcion(String valor) {
    if (valor.trim().isEmpty) return 'La descripción es obligatoria.';
    return null;
  }

  /// Mensaje para el selector de tipo cuando falta la selección obligatoria.
  String? validarTipo() {
    if (_tipo == null) return 'Elige el tipo de problema.';
    return null;
  }

  // ── Envío ─────────────────────────────────────────────────────────────────

  Future<void> enviar() async {
    // Validación de campos obligatorios antes de enviar (CA HU-AL-06):
    // sin tipo elegido o sin descripción no se hace la petición. Tampoco se
    // reenvía mientras la petición esté en vuelo o ya haya sido confirmada
    // (protección contra toques repetidos).
    if (_tipo == null || _descripcion.trim().isEmpty) return;
    if (_status == ReporteIncidenciaStatus.enviando) return;
    if (_status == ReporteIncidenciaStatus.enviado) return;

    _status = ReporteIncidenciaStatus.enviando;
    _error = null;
    _reintentable = false;
    _notificar();

    try {
      _incidencia = await _useCase(
        NuevaIncidencia(
          equipoId: _equipo.id,
          tipo: _tipo!,
          descripcion: _descripcion.trim(),
        ),
      );
      _status = ReporteIncidenciaStatus.enviado;
    } on NetworkException catch (e) {
      _error = e.message;
      _reintentable = true;
      _status = ReporteIncidenciaStatus.error;
    } on ServerException catch (e) {
      _error = e.message;
      _reintentable = true;
      _status = ReporteIncidenciaStatus.error;
    } on AppException catch (e) {
      _error = e.message;
      _status = ReporteIncidenciaStatus.error;
    } catch (_) {
      _error = 'No se pudo enviar el reporte. Inténtalo de nuevo.';
      _reintentable = true;
      _status = ReporteIncidenciaStatus.error;
    } finally {
      _notificar();
    }
  }

  Future<void> reintentar() => enviar();

  void volverAlFormulario() {
    _status = ReporteIncidenciaStatus.formulario;
    _error = null;
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

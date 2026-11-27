// Fakes compartidos de las pruebas de incidencias (HU-AL-06).
// Este archivo no termina en _test.dart: no se ejecuta como prueba.

import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/dominio/incidencia.dart';
import 'package:scei_qr/dominio/nueva_incidencia.dart';
import 'package:scei_qr/features/incidencias/domain/repositories/incidencias_repository.dart';

/// Equipo de ejemplo para las pruebas de reporte (ya identificado).
const Equipo equipoDePrueba = Equipo(
  id: 12,
  identificador: 'LAB-PC-001',
  nombre: 'PC de la fila A',
  ubicacion: 'Fila A, Mesa 3',
  activo: true,
  qrToken: 'qr-token',
);

/// Incidencia de ejemplo tal como la devuelve `POST /incidencias`.
Incidencia incidenciaDePrueba({
  int id = 42,
  TipoProblema tipo = TipoProblema.hardware,
  String descripcion = 'La pantalla parpadea',
}) => Incidencia(
  id: id,
  folio: 'INC-${id.toString().padLeft(6, '0')}',
  equipoId: equipoDePrueba.id,
  alumnoId: 9,
  tipo: tipo,
  descripcion: descripcion,
  estado: EstadoIncidencia.pendiente,
  fechaReporte: DateTime.utc(2026, 11, 25, 10, 30),
  equipoIdentificador: equipoDePrueba.identificador,
  equipoUbicacion: equipoDePrueba.ubicacion,
);

/// Repositorio falso: registra cada envío y puede fallar a pedido.
class FakeIncidenciasRepository implements IncidenciasRepository {
  FakeIncidenciasRepository({this.incidencia, this.error});

  /// Incidencia devuelta en el envío exitoso.
  Incidencia? incidencia;

  /// Si existe, todo envío falla con este error.
  Object? error;

  /// Número de llamadas al repositorio.
  int llamadas = 0;

  /// Último payload recibido (para verificar tipo, descripción, equipo).
  NuevaIncidencia? ultimoEnvio;

  @override
  Future<Incidencia> reportarIncidencia(NuevaIncidencia datos) async {
    llamadas++;
    ultimoEnvio = datos;
    final fallo = error;
    if (fallo != null) throw fallo;
    return incidencia ?? incidenciaDePrueba();
  }
}

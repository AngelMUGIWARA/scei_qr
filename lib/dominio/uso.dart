// CAPA: DOMINIO — Registro de uso de un equipo (HU-AL-03, HU-AL-04).
//
// `inicio` y `fin` son las fechas que asigna el servidor (UTC). La duración
// se calcula siempre con ellas, nunca con la hora del dispositivo.
import 'equipo.dart';

enum EstadoUso {
  activo,
  finalizado;

  static EstadoUso desdeApi(String valor) {
    return valor.toUpperCase() == 'FINALIZADO'
        ? EstadoUso.finalizado
        : EstadoUso.activo;
  }

  String get valorApi => name.toUpperCase();
}

class Uso {
  const Uso({
    required this.id,
    required this.alumnoId,
    required this.equipoId,
    required this.inicio,
    required this.estado,
    this.fin,
    this.equipo,
  });

  final int id;
  final int alumnoId;
  final int equipoId;
  final DateTime inicio;
  final DateTime? fin;
  final EstadoUso estado;
  final Equipo? equipo;

  bool get estaActivo => estado == EstadoUso.activo;

  /// HU-AL-04: duración del uso (`fin - inicio`). Nula mientras el uso
  /// siga activo (el servidor todavía no asignó `fin`).
  Duration? get duracion {
    final fecha = fin;
    if (fecha == null) return null;
    return fecha.difference(inicio);
  }
}

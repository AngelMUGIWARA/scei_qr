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
}

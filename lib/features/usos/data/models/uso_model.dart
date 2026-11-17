import '../../../../dominio/uso.dart';
import '../../../equipos/data/models/equipo_model.dart';

class UsoModel {
  const UsoModel({
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
  final EquipoModel? equipo;

  factory UsoModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawAlumnoId = json['alumnoId'];
    final rawEquipoId = json['equipoId'];
    final rawInicio = json['inicio'];

    if (rawId is! num ||
        rawAlumnoId is! num ||
        rawEquipoId is! num ||
        rawInicio is! String) {
      throw const FormatException('Respuesta de uso inválida');
    }

    final rawEquipo = json['equipo'];
    final rawEstado = json['estado'];

    return UsoModel(
      id: rawId.toInt(),
      alumnoId: rawAlumnoId.toInt(),
      equipoId: rawEquipoId.toInt(),
      inicio: DateTime.parse(rawInicio),
      fin: _fecha(json['fin']),
      estado: EstadoUso.desdeApi(rawEstado is String ? rawEstado : 'ACTIVO'),
      equipo: rawEquipo is Map<String, dynamic>
          ? EquipoModel.fromJson(rawEquipo)
          : null,
    );
  }

  Uso toEntity() => Uso(
    id: id,
    alumnoId: alumnoId,
    equipoId: equipoId,
    inicio: inicio,
    fin: fin,
    estado: estado,
    equipo: equipo?.toEntity(),
  );

  static DateTime? _fecha(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}

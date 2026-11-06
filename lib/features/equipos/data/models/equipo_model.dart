import '../../../../dominio/equipo.dart';

class EquipoModel {
  const EquipoModel({
    required this.id,
    required this.identificador,
    required this.ubicacion,
    required this.activo,
    this.descripcion,
    this.fechaAlta,
  });

  final int id;
  final String identificador;
  final String ubicacion;
  final String? descripcion;
  final bool activo;
  final DateTime? fechaAlta;

  /// Respuesta de `POST /equipos` (equipment_public en `serializers.py`).
  ///
  /// `nombre` y `qrToken` no se mapean: no pertenecen al alcance de HU-AD-04
  /// (el QR es HU-AD-06 y `nombre` es un TODO del contrato, ver
  /// `toCreateEquipoPayload`).
  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: (json['id'] as num).toInt(),
      identificador: json['codigo'] as String,
      ubicacion: json['ubicacion'] as String,
      descripcion: json['descripcion'] as String?,
      // Se exige el campo (sin `?? true`): la verificación del CA "Al guardar,
      // el equipo queda con estado Activo" depende de que el servidor lo envíe.
      activo: json['activo'] as bool,
      fechaAlta: _fecha(json['createdAt']),
    );
  }

  Equipo toEntity() => Equipo(
    id: id,
    identificador: identificador,
    ubicacion: ubicacion,
    descripcion: descripcion,
    activo: activo,
    fechaAlta: fechaAlta,
  );

  static DateTime? _fecha(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}

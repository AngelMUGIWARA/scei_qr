import '../../../../dominio/equipo.dart';

class EquipoModel {
  const EquipoModel({
    required this.id,
    required this.identificador,
    required this.ubicacion,
    required this.activo,
    this.nombre,
    this.descripcion,
    this.fechaAlta,
  });

  final int id;
  final String identificador;
  final String? nombre;
  final String ubicacion;
  final String? descripcion;
  final bool activo;
  final DateTime? fechaAlta;

  /// Alias explícito del contrato: `codigo` en la API.
  String get codigo => identificador;

  /// Respuesta de `POST /equipos` y de `GET /equipos` (equipment_public en
  /// `serializers.py`).
  ///
  /// `qrToken` no se mapea: pertenece a HU-AD-06 y no se utiliza en la
  /// administración de equipos.
  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawCodigo = json['codigo'];
    if (rawId is! num || rawCodigo is! String) {
      throw const FormatException('Respuesta de equipo inválida');
    }

    final rawNombre = json['nombre'];
    return EquipoModel(
      id: rawId.toInt(),
      identificador: rawCodigo,
      nombre: rawNombre is String ? rawNombre.trim() : null,
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
    nombre: nombre,
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

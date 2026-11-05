import '../../../../dominio/tecnico.dart';

class TecnicoModel {
  const TecnicoModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.correo,
    required this.activo,
    this.createdAt,
  });

  final int id;
  final String username;
  final String fullName;
  final String? correo;
  final bool activo;
  final DateTime? createdAt;

  factory TecnicoModel.fromJson(Map<String, dynamic> json) {
    return TecnicoModel(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      correo: json['correo'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: _fecha(json['createdAt']),
    );
  }

  Tecnico toEntity() => Tecnico(
    id: id,
    nombreCompleto: fullName,
    correo: correo ?? '',
    usuario: username,
    activo: activo,
    fechaAlta: createdAt,
  );

  static DateTime? _fecha(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}

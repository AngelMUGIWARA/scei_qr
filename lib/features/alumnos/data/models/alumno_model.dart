import '../../../../dominio/alumno.dart';

/// DTO de `user_public` en `scei_qr_api/app/api/serializers.py`.
///
/// Nota: el backend no expone `fechaBaja`; el estado de la cuenta viene en
/// `activo` y `fechaBaja` queda en `null` al mapear. La fecha de baja solo
/// se conoce en la operación local (`Alumno.darDeBaja`).
class AlumnoModel {
  const AlumnoModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.rol,
    required this.activo,
    required this.fechaAlta,
    this.correo,
    this.matricula,
  });

  final int id;
  final String username;
  final String fullName;
  final String? correo;
  final String? matricula;
  final String rol;
  final bool activo;
  final DateTime fechaAlta;

  factory AlumnoModel.fromJson(Map<String, dynamic> json) {
    return AlumnoModel(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      correo: json['correo'] as String?,
      matricula: json['matricula'] as String?,
      rol: json['rol'] as String,
      // Se exige el campo (sin `?? true`): el estado de la cuenta es el dato
      // que sostiene la baja lógica de HU-AD-12.
      activo: json['activo'] as bool,
      fechaAlta: DateTime.parse(json['createdAt'] as String),
    );
  }

  Alumno toEntity() => Alumno(
    id: id,
    matricula: matricula ?? '',
    nombre: fullName,
    correoInstitucional: correo ?? '',
    usuario: username,
    activo: activo,
    fechaAlta: fechaAlta,
  );
}

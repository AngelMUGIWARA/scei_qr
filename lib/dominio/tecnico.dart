class Tecnico {
  const Tecnico({
    required this.id,
    required this.nombreCompleto,
    required this.correo,
    required this.usuario,
    required this.activo,
    this.fechaAlta,
  });

  final int id;
  final String nombreCompleto;
  final String correo;
  final String usuario;
  final bool activo;
  final DateTime? fechaAlta;

  bool get puedeIniciarSesion => activo;
}

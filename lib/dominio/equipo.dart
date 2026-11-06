// CAPA: DOMINIO — Equipo de cómputo.
//
// El contrato real del backend (`scei_qr_api`, equipment_public) expone
// `codigo`, `nombre`, `descripcion`, `ubicacion`, `activo`; aquí se usa la
// terminología del HU: identificador (= codigo) y ubicación dentro del
// laboratorio (= ubicacion).
//
// TODO-PENDIENTE: `laboratorio` no existe en el contrato actual
// (CreateEquipoRequest, extra="forbid") y por eso no se modela aquí.
class Equipo {
  const Equipo({
    required this.id,
    required this.identificador,
    required this.ubicacion,
    required this.activo,
    this.nombre,
    this.descripcion,
    this.fechaAlta,
    this.qrToken,
  });

  final int id;

  /// Identificador único del equipo (CA HU-AD-04: "El identificador del
  /// equipo debe ser único"). Equivale a `codigo` en el backend.
  final String identificador;

  /// Nombre de visualización. El contrato del backend lo exige, pero el
  /// formulario de alta de HU-AD-04 no lo pide; en ese caso el frontend
  /// reutiliza el identificador.
  final String? nombre;

  /// Ubicación dentro del laboratorio. Equivale a `ubicacion` en el backend.
  final String ubicacion;

  /// Descripción (marca o modelo). Opcional.
  final String? descripcion;

  /// Estado inicial "Activo" que asigna el servidor al crear el equipo
  /// (CA HU-AD-04: "Al guardar, el equipo queda con estado Activo").
  final bool activo;

  final DateTime? fechaAlta;

  /// Payload codificado en el QR del equipo (HU-AD-06: "El QR codifica un
  /// identificador estable y único"). Equivale a `qrToken` en el backend.
  ///
  /// Se regenera solo con `POST /equipos/{id}/regenerar-qr`; al regenerarlo
  /// el anterior deja de resolver (invalidado). Nulo cuando la respuesta no
  /// lo incluyó.
  final String? qrToken;

  /// Nombre visible para la UI, con compatibilidad para registros donde el
  /// backend no devolvió un nombre distinto al código.
  String get nombreVisible {
    final valor = nombre?.trim() ?? '';
    return valor.isEmpty ? identificador : valor;
  }

  bool get estaActivo => activo;

  Equipo copyWith({
    int? id,
    String? identificador,
    String? nombre,
    String? ubicacion,
    String? descripcion,
    bool? activo,
    DateTime? fechaAlta,
    String? qrToken,
  }) {
    return Equipo(
      id: id ?? this.id,
      identificador: identificador ?? this.identificador,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      fechaAlta: fechaAlta ?? this.fechaAlta,
      qrToken: qrToken ?? this.qrToken,
    );
  }
}

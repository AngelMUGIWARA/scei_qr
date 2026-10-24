// CAPA: DOMINIO — Sesión del usuario
// Contrato compartido entre el login (datos) y el guard (presentación).
// `expiraEn` lo calcula la capa de datos a partir de `expiresIn` o del
// claim `exp` del JWT (el token dura 8 h).

import 'rol.dart';

class Sesion {
  const Sesion({
    required this.token,
    required this.rol,
    required this.expiraEn,
    required this.usuarioId,
    required this.username,
    required this.nombreCompleto,
  });

  final String token;
  final Rol rol;
  final DateTime expiraEn;
  final int usuarioId;
  final String username;
  final String nombreCompleto;

  /// `ahora` entra por parámetro para poder probarlo sin depender del reloj.
  bool estaVigente(DateTime ahora) => ahora.isBefore(expiraEn);
}
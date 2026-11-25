import '../../../../dominio/equipo.dart';

/// Registro de uso que quedó pendiente de enviar al backend por falta de
/// conectividad (HU-AL-03: registro sin conexión y reintentos).
class UsoPendiente {
  const UsoPendiente({
    required this.idempotencyKey,
    required this.qrToken,
    required this.equipoId,
    required this.equipoIdentificador,
    required this.creadoEn,
    this.intentos = 0,
  });

  factory UsoPendiente.desdeEquipo({
    required String idempotencyKey,
    required String qrToken,
    required Equipo equipo,
    required DateTime creadoEn,
  }) {
    return UsoPendiente(
      idempotencyKey: idempotencyKey,
      qrToken: qrToken,
      equipoId: equipo.id,
      equipoIdentificador: equipo.identificador,
      creadoEn: creadoEn,
    );
  }

  /// Clave estable del registro; se reutiliza en cada reintento.
  final String idempotencyKey;

  /// Token del QR escaneado, necesario para registrar el uso.
  final String qrToken;

  /// Datos del equipo para mostrarlo al alumno mientras está pendiente.
  final int equipoId;
  final String equipoIdentificador;

  /// Momento en que se intentó registrar por primera vez.
  final DateTime creadoEn;

  /// Número de intentos fallidos de sincronización.
  final int intentos;

  UsoPendiente copyWith({DateTime? creadoEn, int? intentos}) {
    return UsoPendiente(
      idempotencyKey: idempotencyKey,
      qrToken: qrToken,
      equipoId: equipoId,
      equipoIdentificador: equipoIdentificador,
      creadoEn: creadoEn ?? this.creadoEn,
      intentos: intentos ?? this.intentos,
    );
  }
}

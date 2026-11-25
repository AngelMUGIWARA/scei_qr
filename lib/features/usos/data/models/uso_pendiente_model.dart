import '../../domain/uso_pendiente.dart';

class UsoPendienteModel {
  const UsoPendienteModel({
    required this.idempotencyKey,
    required this.qrToken,
    required this.equipoId,
    required this.equipoIdentificador,
    required this.creadoEn,
    required this.intentos,
  });

  factory UsoPendienteModel.fromEntity(UsoPendiente pendiente) {
    return UsoPendienteModel(
      idempotencyKey: pendiente.idempotencyKey,
      qrToken: pendiente.qrToken,
      equipoId: pendiente.equipoId,
      equipoIdentificador: pendiente.equipoIdentificador,
      creadoEn: pendiente.creadoEn,
      intentos: pendiente.intentos,
    );
  }

  factory UsoPendienteModel.fromJson(Map<String, dynamic> json) {
    final idempotencyKey = json['idempotencyKey'];
    final qrToken = json['qrToken'];
    final equipoId = json['equipoId'];
    final equipoIdentificador = json['equipoIdentificador'];
    final creadoEn = json['creadoEn'];

    if (idempotencyKey is! String ||
        qrToken is! String ||
        equipoId is! num ||
        equipoIdentificador is! String ||
        creadoEn is! String) {
      throw const FormatException('Registro de uso pendiente inválido');
    }

    final fecha = DateTime.tryParse(creadoEn);
    if (fecha == null) {
      throw const FormatException('Fecha de uso pendiente inválida');
    }

    final intentos = json['intentos'];
    return UsoPendienteModel(
      idempotencyKey: idempotencyKey,
      qrToken: qrToken,
      equipoId: equipoId.toInt(),
      equipoIdentificador: equipoIdentificador,
      creadoEn: fecha,
      intentos: intentos is num ? intentos.toInt() : 0,
    );
  }

  final String idempotencyKey;
  final String qrToken;
  final int equipoId;
  final String equipoIdentificador;
  final DateTime creadoEn;
  final int intentos;

  Map<String, dynamic> toJson() => {
    'idempotencyKey': idempotencyKey,
    'qrToken': qrToken,
    'equipoId': equipoId,
    'equipoIdentificador': equipoIdentificador,
    'creadoEn': creadoEn.toIso8601String(),
    'intentos': intentos,
  };

  UsoPendiente toEntity() => UsoPendiente(
    idempotencyKey: idempotencyKey,
    qrToken: qrToken,
    equipoId: equipoId,
    equipoIdentificador: equipoIdentificador,
    creadoEn: creadoEn,
    intentos: intentos,
  );
}

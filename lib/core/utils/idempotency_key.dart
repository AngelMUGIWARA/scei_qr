import 'dart:math';

/// Genera una clave de idempotencia única para un registro de uso.
///
/// Permite que un reintento (manual o automático) no duplique el uso en el
/// backend: el servidor puede reconocer la misma clave y devolver el registro
/// existente en lugar de crear otro.
String generarIdempotencyKey([Random? random]) {
  final generador = random ?? Random.secure();
  final marcaTiempo = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final aleatorio = List<String>.generate(
    4,
    (_) => generador.nextInt(1 << 16).toRadixString(16).padLeft(4, '0'),
  ).join();
  return '$marcaTiempo-$aleatorio';
}

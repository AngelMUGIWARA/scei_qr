import '../../../../dominio/uso.dart';

enum EstadoRegistroUso { registrado, pendiente }

/// Resultado de intentar registrar un uso.
///
/// [EstadoRegistroUso.registrado] indica que el backend confirmó el uso.
/// [EstadoRegistroUso.pendiente] indica que faltó conexión y el registro quedó
/// guardado localmente para sincronizarse después.
class RegistroUsoResultado {
  const RegistroUsoResultado.registrado(this.uso)
    : estado = EstadoRegistroUso.registrado;

  const RegistroUsoResultado.pendiente()
    : estado = EstadoRegistroUso.pendiente,
      uso = null;

  final EstadoRegistroUso estado;
  final Uso? uso;

  bool get esPendiente => estado == EstadoRegistroUso.pendiente;
}

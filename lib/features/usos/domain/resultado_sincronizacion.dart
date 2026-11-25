/// Resumen de una ejecución de sincronización de usos pendientes.
class ResultadoSincronizacion {
  const ResultadoSincronizacion({
    this.sincronizados = 0,
    this.fallidos = 0,
    this.pendientesRestantes = 0,
    this.interrumpido = false,
  });

  /// Pendientes que se enviaron correctamente o que el backend descartó.
  final int sincronizados;

  /// Pendientes que fallaron por un error transitorio y siguen en la cola.
  final int fallidos;

  /// Total de pendientes que quedan tras la sincronización.
  final int pendientesRestantes;

  /// `true` si se detuvo por falta de conexión o de sesión válida.
  final bool interrumpido;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/uso.dart';
import '../../../incidencias/presentation/screens/reportar_incidencia_screen.dart';
import '../../domain/repositories/usos_repository.dart';
import '../../domain/usecases/finalizar_uso_usecase.dart';
import '../../domain/usecases/obtener_uso_activo_usecase.dart';
import '../providers/uso_activo_provider.dart';

/// HU-AL-04: tarjeta del uso activo del alumno con el botón "Finalizar uso"
/// y, al terminar, el resumen del uso.
///
/// HU-AL-06: mientras el uso siga activo también ofrece "Reportar
/// incidencia", que abre el formulario con el equipo del uso ya
/// identificado; desaparece al finalizar (solo queda el resumen).
///
/// Consulta `GET /usos/mis-registros` al crearse (cubre reabrir la app con
/// un uso activo) y de nuevo cada vez que su pantalla vuelve a quedar visible
/// (por ejemplo, al regresar del registro de uso de HU-AL-03).
class UsoActivoCard extends StatelessWidget {
  const UsoActivoCard({
    super.key,
    this.obtenerUsoActivoUseCase,
    this.finalizarUsoUseCase,
  });

  final ObtenerUsoActivoUseCase? obtenerUsoActivoUseCase;
  final FinalizarUsoUseCase? finalizarUsoUseCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final repository =
            (obtenerUsoActivoUseCase == null || finalizarUsoUseCase == null)
            ? context.read<UsosRepository>()
            : null;
        return UsoActivoProvider(
          obtenerUsoActivoUseCase:
              obtenerUsoActivoUseCase ?? ObtenerUsoActivoUseCase(repository!),
          finalizarUsoUseCase:
              finalizarUsoUseCase ?? FinalizarUsoUseCase(repository!),
        )..cargar();
      },
      child: const _RecargarAlVolver(child: _UsoActivoBody()),
    );
  }
}

/// Vuelve a consultar el uso activo cuando la ruta que contiene la tarjeta
/// pasa de oculta a visible.
class _RecargarAlVolver extends StatefulWidget {
  const _RecargarAlVolver({required this.child});

  final Widget child;

  @override
  State<_RecargarAlVolver> createState() => _RecargarAlVolverState();
}

class _RecargarAlVolverState extends State<_RecargarAlVolver> {
  bool? _eraVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible && _eraVisible == false) {
      // Fuera de la fase de build para no notificar mientras se construye.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<UsoActivoProvider>().cargar();
      });
    }
    _eraVisible = visible;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UsoActivoBody extends StatelessWidget {
  const _UsoActivoBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsoActivoProvider>();

    switch (provider.status) {
      case UsoActivoStatus.cargando:
        return const Padding(
          key: Key('uso_activo_cargando'),
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(),
        );

      case UsoActivoStatus.sinUso:
        final mensaje = provider.mensaje;
        if (mensaje == null) {
          return const SizedBox.shrink(key: Key('uso_activo_sin_uso'));
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(mensaje, key: const Key('uso_activo_mensaje')),
        );

      case UsoActivoStatus.error:
        return Card(
          key: const Key('uso_activo_error'),
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(
              provider.mensaje ?? 'No se pudo consultar tu uso activo.',
              key: const Key('uso_activo_mensaje'),
            ),
            trailing: TextButton(
              key: const Key('uso_activo_reintentar'),
              onPressed: provider.cargar,
              child: const Text('Reintentar'),
            ),
          ),
        );

      case UsoActivoStatus.activo:
      case UsoActivoStatus.finalizando:
        final uso = provider.usoActivo!;
        return _UsoEnCurso(
          uso: uso,
          finalizando: provider.status == UsoActivoStatus.finalizando,
          mensaje: provider.mensaje,
          onFinalizar: provider.finalizar,
          // HU-AL-06: solo con el uso activo y con el equipo ya
          // identificado; el resumen de uso finalizado no reporta.
          onReportar: uso.equipo == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ReportarIncidenciaScreen(equipo: uso.equipo!),
                  ),
                ),
        );

      case UsoActivoStatus.finalizado:
        return _ResumenUso(uso: provider.usoFinalizado!);
    }
  }
}

class _UsoEnCurso extends StatelessWidget {
  const _UsoEnCurso({
    required this.uso,
    required this.finalizando,
    required this.mensaje,
    required this.onFinalizar,
    required this.onReportar,
  });

  final Uso uso;
  final bool finalizando;
  final String? mensaje;
  final Future<void> Function() onFinalizar;

  /// HU-AL-06: navega al formulario de reporte con el equipo del uso.
  /// `null` cuando el backend no devolvió el equipo embebido: en ese caso
  /// no se ofrece reportar (no hay equipo que identificar).
  final VoidCallback? onReportar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('uso_activo_en_curso'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uso en curso',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Equipo: ${codigoEquipo(uso)}',
              key: const Key('uso_activo_equipo'),
            ),
            Text(
              'Inicio: ${formatearFechaHoraLocal(uso.inicio)}',
              key: const Key('uso_activo_inicio'),
            ),
            if (mensaje != null) ...[
              const SizedBox(height: 8),
              Text(
                mensaje!,
                key: const Key('uso_activo_mensaje'),
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('uso_activo_finalizar'),
              onPressed: finalizando ? null : () => onFinalizar(),
              icon: finalizando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.stop_circle_outlined),
              label: const Text('Finalizar uso'),
            ),
            // HU-AL-06: reportar incidencia del equipo mientras el uso
            // siga activo (no aparece en el resumen posterior).
            if (onReportar != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('uso_activo_reportar_incidencia'),
                onPressed: finalizando ? null : onReportar,
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Reportar incidencia'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// CA4: resumen con equipo, hora de inicio, hora de fin y duración.
class _ResumenUso extends StatelessWidget {
  const _ResumenUso({required this.uso});

  final Uso uso;

  @override
  Widget build(BuildContext context) {
    final fin = uso.fin;
    final duracion = uso.duracion;
    return Card(
      key: const Key('uso_activo_resumen'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uso finalizado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Equipo: ${codigoEquipo(uso)}',
              key: const Key('uso_resumen_equipo'),
            ),
            Text(
              'Inicio: ${formatearFechaHoraLocal(uso.inicio)}',
              key: const Key('uso_resumen_inicio'),
            ),
            Text(
              'Fin: ${fin == null ? '—' : formatearFechaHoraLocal(fin)}',
              key: const Key('uso_resumen_fin'),
            ),
            Text(
              'Duración: ${duracion == null ? '—' : formatearDuracion(duracion)}',
              key: const Key('uso_resumen_duracion'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Código del equipo (identificador legible); si la respuesta no trajo el
/// equipo se usa su id.
String codigoEquipo(Uso uso) =>
    uso.equipo?.identificador ?? 'Equipo #${uso.equipoId}';

/// Fechas del servidor (UTC) mostradas en la hora local del dispositivo.
String formatearFechaHoraLocal(DateTime valor) {
  final local = valor.toLocal();
  String dos(int numero) => numero.toString().padLeft(2, '0');
  return '${dos(local.day)}/${dos(local.month)}/${local.year} '
      '${dos(local.hour)}:${dos(local.minute)}';
}

/// Duración legible: "1 h 05 min", "45 min" o "30 s".
String formatearDuracion(Duration duracion) {
  final total = duracion.isNegative ? Duration.zero : duracion;
  final horas = total.inHours;
  final minutos = total.inMinutes.remainder(60);
  if (horas > 0) return '$horas h ${minutos.toString().padLeft(2, '0')} min';
  if (total.inMinutes > 0) return '${total.inMinutes} min';
  return '${total.inSeconds} s';
}

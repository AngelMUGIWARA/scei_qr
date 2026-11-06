import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/equipo.dart';
import '../../domain/repositories/equipos_repository.dart';
import '../../domain/usecases/obtener_equipo_usecase.dart';
import '../../domain/usecases/obtener_imagen_qr_usecase.dart';
import '../../domain/usecases/regenerar_qr_usecase.dart';
import '../providers/detalle_equipo_provider.dart';

/// HU-AD-06: detalle del equipo con visualización del QR y regeneración
/// (la regeneración invalida el QR anterior y se informa al administrador).
class DetalleEquipoScreen extends StatelessWidget {
  const DetalleEquipoScreen({
    super.key,
    required this.equipoId,
    this.equipoInicial,
    this.obtenerEquipoUseCase,
    this.obtenerImagenQrUseCase,
    this.regenerarQrUseCase,
  });

  final int equipoId;
  final Equipo? equipoInicial;
  final ObtenerEquipoUseCase? obtenerEquipoUseCase;
  final ObtenerImagenQrUseCase? obtenerImagenQrUseCase;
  final RegenerarQrUseCase? regenerarQrUseCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final repository =
            obtenerEquipoUseCase == null ||
            obtenerImagenQrUseCase == null ||
            regenerarQrUseCase == null
            ? context.read<EquiposRepository>()
            : null;
        return DetalleEquipoProvider(
          equipoId: equipoId,
          equipoInicial: equipoInicial,
          obtenerEquipoUseCase:
              obtenerEquipoUseCase ?? ObtenerEquipoUseCase(repository!),
          obtenerImagenQrUseCase:
              obtenerImagenQrUseCase ?? ObtenerImagenQrUseCase(repository!),
          regenerarQrUseCase:
              regenerarQrUseCase ?? RegenerarQrUseCase(repository!),
        )..cargar();
      },
      child: const _DetalleEquipoBody(),
    );
  }
}

class _DetalleEquipoBody extends StatelessWidget {
  const _DetalleEquipoBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DetalleEquipoProvider>();
    final equipo = provider.equipo;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del equipo')),
      body: _contenido(provider, equipo),
    );
  }

  Widget _contenido(DetalleEquipoProvider provider, Equipo? equipo) {
    if (equipo == null && provider.cargandoEquipo) {
      return const Center(
        child: CircularProgressIndicator(key: Key('detalle_equipo_cargando')),
      );
    }

    if (equipo == null) {
      return _ErrorCarga(
        mensaje:
            provider.errorEquipo ??
            'No se pudo cargar el equipo. Inténtalo de nuevo.',
        onReintentar: provider.cargar,
      );
    }

    return _DetalleEquipoVista(provider: provider, equipo: equipo);
  }
}

class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el equipo',
              key: const Key('detalle_equipo_error'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const Key('detalle_equipo_reintentar'),
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleEquipoVista extends StatelessWidget {
  const _DetalleEquipoVista({required this.provider, required this.equipo});

  final DetalleEquipoProvider provider;
  final Equipo equipo;

  Future<void> _confirmarRegeneracion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('regenerar_qr_dialog'),
        icon: const Icon(Icons.qr_code_2),
        title: const Text('Regenerar código QR'),
        content: const Text(
          'Se generará un código QR nuevo para este equipo. El código '
          'anterior dejará de ser válido y no podrá escanearse.',
        ),
        actions: [
          TextButton(
            key: const Key('regenerar_qr_cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('regenerar_qr_confirmar'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Regenerar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    final ok = await provider.regenerarQr();
    if (!context.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            key: const Key('regenerar_qr_error_snackbar'),
            content: Text(
              provider.errorAccion ??
                  'No se pudo regenerar el QR. Inténtalo de nuevo.',
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      return;
    }

    // CA HU-AD-06: se informa al administrador que el QR anterior dejó de
    // ser válido.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('regenerar_qr_exito_dialog'),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('QR regenerado'),
        content: const Text(
          'El código QR anterior dejó de ser válido. Muestra el nuevo '
          'código QR al equipo.',
        ),
        actions: [
          TextButton(
            key: const Key('regenerar_qr_exito_aceptar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    provider.limpiarMensajes();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                key: const Key('detalle_equipo_datos'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: equipo.activo
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.computer,
                              color: equipo.activo
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipo.identificador,
                                  key: const Key('detalle_equipo_identificador'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (equipo.nombreVisible !=
                                    equipo.identificador)
                                  Text(equipo.nombreVisible),
                              ],
                            ),
                          ),
                          Chip(
                            key: const Key('detalle_equipo_estado'),
                            label: Text(equipo.activo ? 'Activo' : 'Inactivo'),
                            backgroundColor: equipo.activo
                                ? Colors.green.withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHighest,
                            labelStyle: TextStyle(
                              color: equipo.activo
                                  ? Colors.green.shade800
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _Dato(
                        icono: Icons.place_outlined,
                        etiqueta: 'Ubicación dentro del laboratorio',
                        valor: equipo.ubicacion,
                      ),
                      if ((equipo.descripcion ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _Dato(
                          icono: Icons.info_outline,
                          etiqueta: 'Descripción (marca o modelo)',
                          valor: equipo.descripcion!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                key: const Key('detalle_equipo_qr_card'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Código QR',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Único y estable: identifica este equipo al escanearlo.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      _contenidoQr(context, provider),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('detalle_equipo_regenerar_qr'),
                onPressed: provider.regenerando
                    ? null
                    : () => _confirmarRegeneracion(context),
                icon: provider.regenerando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  provider.regenerando
                      ? 'Regenerando…'
                      : 'Regenerar código QR',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenidoQr(BuildContext context, DetalleEquipoProvider provider) {
    if (provider.cargandoQr) {
      return const SizedBox(
        height: 200,
        width: 200,
        child: Center(
          child: CircularProgressIndicator(key: Key('detalle_equipo_qr_cargando')),
        ),
      );
    }

    if (provider.errorQr != null) {
      return Column(
        children: [
          Icon(
            Icons.qr_code_2,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorQr!,
            key: const Key('detalle_equipo_qr_error'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            key: const Key('detalle_equipo_qr_reintentar'),
            onPressed: provider.cargarQr,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    final bytes = provider.qrBytes;
    if (bytes == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Image.memory(
          bytes,
          key: const Key('detalle_equipo_qr_imagen'),
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Escanea este código para identificar el equipo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.etiqueta, required this.valor});

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(valor),
            ],
          ),
        ),
      ],
    );
  }
}

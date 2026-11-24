import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/printing/impresion_service.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/repositories/equipos_repository.dart';
import '../../domain/usecases/descargar_etiqueta_qr_usecase.dart';
import '../../domain/usecases/descargar_etiquetas_lote_usecase.dart';
import '../../domain/usecases/listar_equipos_usecase.dart';
import '../providers/gestion_codigos_qr_provider.dart';

/// HU-AD-07: descargar e imprimir los códigos QR de los equipos, tanto de
/// forma individual como por lote (por ejemplo, todo un laboratorio).
class GestionarCodigosQrScreen extends StatelessWidget {
  const GestionarCodigosQrScreen({
    super.key,
    this.listarEquiposUseCase,
    this.descargarEtiquetaQrUseCase,
    this.descargarEtiquetasLoteUseCase,
    this.impresionService,
  });

  final ListarEquiposUseCase? listarEquiposUseCase;
  final DescargarEtiquetaQrUseCase? descargarEtiquetaQrUseCase;
  final DescargarEtiquetasLoteUseCase? descargarEtiquetasLoteUseCase;
  final ImpresionService? impresionService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final requiereRepositorio =
            listarEquiposUseCase == null ||
            descargarEtiquetaQrUseCase == null ||
            descargarEtiquetasLoteUseCase == null;
        final repository = requiereRepositorio
            ? context.read<EquiposRepository>()
            : null;

        return GestionCodigosQrProvider(
          listarEquiposUseCase:
              listarEquiposUseCase ?? ListarEquiposUseCase(repository!),
          descargarEtiquetaQrUseCase:
              descargarEtiquetaQrUseCase ??
              DescargarEtiquetaQrUseCase(repository!),
          descargarEtiquetasLoteUseCase:
              descargarEtiquetasLoteUseCase ??
              DescargarEtiquetasLoteUseCase(repository!),
          impresionService:
              impresionService ?? const PrintingImpresionService(),
        )..cargar();
      },
      child: const _GestionCodigosQrView(),
    );
  }
}

class _GestionCodigosQrView extends StatefulWidget {
  const _GestionCodigosQrView();

  @override
  State<_GestionCodigosQrView> createState() => _GestionCodigosQrViewState();
}

class _GestionCodigosQrViewState extends State<_GestionCodigosQrView> {
  final _laboratorioController = TextEditingController();
  final _ubicacionController = TextEditingController();

  @override
  void dispose() {
    _laboratorioController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GestionCodigosQrProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Códigos QR y etiquetas'),
        actions: [
          IconButton(
            key: const Key('etiquetas_actualizar'),
            tooltip: 'Actualizar',
            onPressed: provider.cargando
                ? null
                : () => provider.cargar(mostrarCarga: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _Filtros(
            laboratorioController: _laboratorioController,
            ubicacionController: _ubicacionController,
            provider: provider,
          ),
          if (provider.cargando) const LinearProgressIndicator(),
          if (provider.hayFiltros && !provider.cargando)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${provider.equipos.length} equipo(s) en el lote',
                    key: const Key('etiquetas_conteo'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('etiquetas_limpiar_filtros'),
                    onPressed: provider.limpiarFiltros,
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
          Expanded(child: _contenido(context, provider)),
        ],
      ),
      bottomNavigationBar: _AccionesLote(provider: provider),
    );
  }

  Widget _contenido(BuildContext context, GestionCodigosQrProvider provider) {
    if (provider.cargando && provider.equipos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('etiquetas_cargando')),
      );
    }

    if (provider.error != null && provider.equipos.isEmpty) {
      return _EstadoVacio(
        key: const Key('etiquetas_error'),
        icono: Icons.cloud_off,
        titulo: 'No se pudieron cargar los equipos',
        mensaje: provider.error!,
        accion: FilledButton.tonal(
          key: const Key('etiquetas_reintentar'),
          onPressed: () => provider.cargar(),
          child: const Text('Reintentar'),
        ),
      );
    }

    if (provider.equipos.isEmpty) {
      return _EstadoVacio(
        key: const Key('etiquetas_vacio'),
        icono: Icons.print_disabled,
        titulo: 'No hay equipos para etiquetar',
        mensaje: provider.hayFiltros
            ? 'Ajusta el laboratorio o la ubicación e inténtalo de nuevo.'
            : 'Registra equipos para poder generar sus etiquetas.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.cargar(mostrarCarga: false),
      child: ListView.separated(
        key: const Key('etiquetas_lista'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: provider.equipos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final equipo = provider.equipos[index];
          return _EquipoEtiquetaCard(
            equipo: equipo,
            procesando: provider.procesandoId == equipo.id,
            onDescargar: () => _ejecutar(
              context,
              () => provider.procesarEquipo(equipo, imprimir: false),
            ),
            onImprimir: () => _ejecutar(
              context,
              () => provider.procesarEquipo(equipo, imprimir: true),
            ),
          );
        },
      ),
    );
  }

  Future<void> _ejecutar(
    BuildContext context,
    Future<bool> Function() accion,
  ) async {
    await accion();
    if (!context.mounted) return;
    final provider = context.read<GestionCodigosQrProvider>();
    final mensaje = provider.errorAccion ?? provider.mensajeAccion;
    if (mensaje == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('etiquetas_snackbar'),
          content: Text(mensaje),
          backgroundColor: provider.errorAccion != null
              ? Theme.of(context).colorScheme.errorContainer
              : null,
        ),
      );
    provider.limpiarMensajes();
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.laboratorioController,
    required this.ubicacionController,
    required this.provider,
  });

  final TextEditingController laboratorioController;
  final TextEditingController ubicacionController;
  final GestionCodigosQrProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('etiquetas_laboratorio_field'),
                controller: laboratorioController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Laboratorio',
                  hintText: 'Ej. Laboratorio de Cómputo 1',
                  prefixIcon: Icon(Icons.science_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _aplicar(),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('etiquetas_ubicacion_field'),
                controller: ubicacionController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (opcional)',
                  hintText: 'Ej. Fila A',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _aplicar(),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('etiquetas_aplicar_filtros'),
                onPressed: _aplicar,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Generar lote de este filtro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _aplicar() {
    provider.actualizarFiltros(
      laboratorio: laboratorioController.text,
      ubicacion: ubicacionController.text,
    );
  }
}

class _EquipoEtiquetaCard extends StatelessWidget {
  const _EquipoEtiquetaCard({
    required this.equipo,
    required this.procesando,
    required this.onDescargar,
    required this.onImprimir,
  });

  final Equipo equipo;
  final bool procesando;
  final VoidCallback onDescargar;
  final VoidCallback onImprimir;

  @override
  Widget build(BuildContext context) {
    final detalles = <String>[
      if ((equipo.laboratorio ?? '').trim().isNotEmpty)
        'Laboratorio: ${equipo.laboratorio}',
      'Ubicación: ${equipo.ubicacion}',
    ];

    return Card(
      key: ValueKey('etiqueta_equipo_${equipo.id}'),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.qr_code_2)),
        title: Text(
          equipo.identificador,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(detalles.join(' · ')),
        trailing: procesando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    key: ValueKey('etiqueta_descargar_${equipo.id}'),
                    tooltip: 'Descargar etiqueta PDF',
                    onPressed: onDescargar,
                    icon: const Icon(Icons.download_outlined),
                  ),
                  IconButton(
                    key: ValueKey('etiqueta_imprimir_${equipo.id}'),
                    tooltip: 'Imprimir etiqueta',
                    onPressed: onImprimir,
                    icon: const Icon(Icons.print_outlined),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AccionesLote extends StatelessWidget {
  const _AccionesLote({required this.provider});

  final GestionCodigosQrProvider provider;

  @override
  Widget build(BuildContext context) {
    final habilitado = provider.equipos.isNotEmpty && !provider.procesandoLote;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('etiquetas_descargar_lote'),
              onPressed: habilitado
                  ? () => _ejecutar(context, imprimir: false)
                  : null,
              icon: provider.procesandoLote
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Descargar lote'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              key: const Key('etiquetas_imprimir_lote'),
              onPressed: habilitado
                  ? () => _ejecutar(context, imprimir: true)
                  : null,
              icon: const Icon(Icons.print_outlined),
              label: const Text('Imprimir lote'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutar(BuildContext context, {required bool imprimir}) async {
    await provider.procesarLote(imprimir: imprimir);
    if (!context.mounted) return;
    final mensaje = provider.errorAccion ?? provider.mensajeAccion;
    if (mensaje == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('etiquetas_lote_snackbar'),
          content: Text(mensaje),
          backgroundColor: provider.errorAccion != null
              ? Theme.of(context).colorScheme.errorContainer
              : null,
        ),
      );
    provider.limpiarMensajes();
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}

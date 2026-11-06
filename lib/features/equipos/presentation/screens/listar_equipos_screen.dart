import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/equipo.dart';
import '../../domain/repositories/equipos_repository.dart';
import '../../domain/usecases/cambiar_estado_equipo_usecase.dart';
import '../../domain/usecases/listar_equipos_usecase.dart';
import '../providers/listar_equipos_provider.dart';
import 'detalle_equipo_screen.dart';
import 'editar_equipo_screen.dart';

enum _FiltroEstado { todos, activos, inactivos }

class ListarEquiposScreen extends StatelessWidget {
  const ListarEquiposScreen({
    super.key,
    this.listarEquiposUseCase,
    this.cambiarEstadoEquipoUseCase,
  });

  final ListarEquiposUseCase? listarEquiposUseCase;
  final CambiarEstadoEquipoUseCase? cambiarEstadoEquipoUseCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final repository =
            listarEquiposUseCase == null || cambiarEstadoEquipoUseCase == null
            ? context.read<EquiposRepository>()
            : null;
        return ListarEquiposProvider(
          listarEquiposUseCase:
              listarEquiposUseCase ?? ListarEquiposUseCase(repository!),
          cambiarEstadoEquipoUseCase:
              cambiarEstadoEquipoUseCase ??
              CambiarEstadoEquipoUseCase(repository!),
        )..cargar();
      },
      child: const _ListarEquiposView(),
    );
  }
}

class _ListarEquiposView extends StatefulWidget {
  const _ListarEquiposView();

  @override
  State<_ListarEquiposView> createState() => _ListarEquiposViewState();
}

class _ListarEquiposViewState extends State<_ListarEquiposView> {
  final _busquedaController = TextEditingController();
  final _ubicacionController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListarEquiposProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar equipos'),
        actions: [
          IconButton(
            key: const Key('equipos_actualizar'),
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
            busquedaController: _busquedaController,
            ubicacionController: _ubicacionController,
            provider: provider,
          ),
          if (provider.cargando || provider.refrescando)
            const LinearProgressIndicator(),
          if (provider.hayError && provider.equipos.isNotEmpty)
            _BannerError(mensaje: provider.errorMessage),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.cargar(mostrarCarga: false),
              child: _contenido(context, provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(BuildContext context, ListarEquiposProvider provider) {
    if ((provider.status == ListarEquiposStatus.inicial || provider.cargando) &&
        provider.equipos.isEmpty) {
      return _scrollable(
        const SizedBox(
          height: 320,
          child: Center(
            child: CircularProgressIndicator(key: Key('equipos_cargando')),
          ),
        ),
      );
    }

    if (provider.hayError && provider.equipos.isEmpty) {
      return _scrollable(
        _EstadoVacio(
          key: const Key('equipos_error'),
          icono: Icons.cloud_off,
          titulo: 'No se pudieron cargar los equipos',
          mensaje:
              provider.errorMessage ??
              'Revisa tu conexión e inténtalo de nuevo.',
          accion: FilledButton.tonal(
            key: const Key('equipos_reintentar'),
            onPressed: () => provider.cargar(),
            child: const Text('Reintentar'),
          ),
        ),
      );
    }

    if (provider.equipos.isEmpty) {
      return _scrollable(
        _EstadoVacio(
          key: const Key('equipos_vacio'),
          icono: provider.hayFiltros ? Icons.search_off : Icons.devices_other,
          titulo: provider.hayFiltros
              ? 'No hay equipos que coincidan'
              : 'Aún no hay equipos registrados',
          mensaje: provider.hayFiltros
              ? 'Ajusta la búsqueda o los filtros para ver más resultados.'
              : 'Registra un equipo desde el panel de administración.',
          accion: provider.hayFiltros
              ? TextButton(
                  key: const Key('equipos_limpiar_filtros_vacio'),
                  onPressed: () {
                    _busquedaController.clear();
                    _ubicacionController.clear();
                    provider.limpiarFiltros();
                  },
                  child: const Text('Limpiar filtros'),
                )
              : null,
        ),
      );
    }

    return ListView.separated(
      key: const Key('equipos_lista'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: provider.equipos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final equipo = provider.equipos[index];
        return _EquipoCard(
          equipo: equipo,
          procesando: provider.procesandoId == equipo.id,
          onAbrirDetalle: () => _abrirDetalle(context, equipo),
          onEditar: () => _abrirEditar(context, provider, equipo),
          onCambiarEstado: () =>
              _confirmarCambioEstado(context, provider, equipo),
        );
      },
    );
  }

  Widget _scrollable(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [child],
    );
  }

  /// HU-AD-06: al tocar la tarjeta se abre el detalle, donde se visualiza
  /// el QR del equipo.
  void _abrirDetalle(BuildContext context, Equipo equipo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalleEquipoScreen(
          equipoId: equipo.id,
          equipoInicial: equipo,
        ),
      ),
    );
  }

  Future<void> _abrirEditar(
    BuildContext context,
    ListarEquiposProvider provider,
    Equipo equipo,
  ) async {
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            EditarEquipoScreen(equipoId: equipo.id, equipoInicial: equipo),
      ),
    );

    if (actualizado == true) {
      await provider.cargar(mostrarCarga: false);
    }
  }

  Future<void> _confirmarCambioEstado(
    BuildContext context,
    ListarEquiposProvider provider,
    Equipo equipo,
  ) async {
    final esBaja = equipo.activo;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('cambiar_estado_dialog'),
        icon: Icon(esBaja ? Icons.warning_amber : Icons.restore),
        title: Text(esBaja ? 'Dar de baja equipo' : 'Reactivar equipo'),
        content: Text(
          esBaja
              ? 'El equipo ${equipo.identificador} quedará inactivo y no '
                    'podrá asignarse a nuevos préstamos.'
              : 'El equipo ${equipo.identificador} volverá a estar activo.',
        ),
        actions: [
          TextButton(
            key: const Key('cambiar_estado_cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('cambiar_estado_confirmar'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(esBaja ? 'Dar de baja' : 'Reactivar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final ok = await provider.cambiarEstado(equipo);
    if (!context.mounted) return;

    final mensaje = ok
        ? provider.mensajeAccion
        : provider.errorAccion ?? 'No se pudo actualizar el equipo.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje ?? 'Operación completada.'),
          backgroundColor: ok
              ? null
              : Theme.of(context).colorScheme.errorContainer,
        ),
      );
    provider.limpiarMensajes();
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.busquedaController,
    required this.ubicacionController,
    required this.provider,
  });

  final TextEditingController busquedaController;
  final TextEditingController ubicacionController;
  final ListarEquiposProvider provider;

  _FiltroEstado get _filtroSeleccionado {
    final activo = provider.activo;
    if (activo == null) return _FiltroEstado.todos;
    return activo ? _FiltroEstado.activos : _FiltroEstado.inactivos;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('equipos_busqueda_field'),
            controller: busquedaController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Buscar por código, nombre o descripción',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                key: const Key('equipos_busqueda_limpiar'),
                tooltip: 'Limpiar búsqueda',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  busquedaController.clear();
                  provider.actualizarBusqueda('');
                },
              ),
            ),
            onChanged: provider.actualizarBusqueda,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('equipos_ubicacion_field'),
            controller: ubicacionController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Filtrar por ubicación',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: provider.actualizarUbicacion,
          ),
          const SizedBox(height: 8),
          SegmentedButton<_FiltroEstado>(
            key: const Key('equipos_estado_filtro'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _FiltroEstado.todos, label: Text('Todos')),
              ButtonSegment(
                value: _FiltroEstado.activos,
                label: Text('Activos'),
              ),
              ButtonSegment(
                value: _FiltroEstado.inactivos,
                label: Text('Inactivos'),
              ),
            ],
            selected: {_filtroSeleccionado},
            onSelectionChanged: (seleccion) {
              final valor = seleccion.first;
              provider.actualizarEstado(switch (valor) {
                _FiltroEstado.todos => null,
                _FiltroEstado.activos => true,
                _FiltroEstado.inactivos => false,
              });
            },
          ),
          if (provider.hayFiltros)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('equipos_limpiar_filtros'),
                onPressed: () {
                  busquedaController.clear();
                  ubicacionController.clear();
                  provider.limpiarFiltros();
                },
                child: const Text('Limpiar filtros'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EquipoCard extends StatelessWidget {
  const _EquipoCard({
    required this.equipo,
    required this.procesando,
    required this.onAbrirDetalle,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  final Equipo equipo;
  final bool procesando;
  final VoidCallback onAbrirDetalle;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final detalles = <String>[
      'Ubicación: ${equipo.ubicacion}',
      if ((equipo.descripcion ?? '').trim().isNotEmpty) equipo.descripcion!,
    ];

    return Card(
      key: ValueKey('equipo_card_${equipo.id}'),
      child: ListTile(
        // HU-AD-06: la tarjeta abre el detalle (visualización del QR).
        onTap: onAbrirDetalle,
        leading: CircleAvatar(
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
        title: Text(
          equipo.identificador,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (equipo.nombreVisible != equipo.identificador)
              Text(equipo.nombreVisible),
            for (final detalle in detalles)
              Text(detalle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Chip(
              key: ValueKey('equipo_estado_${equipo.id}'),
              visualDensity: VisualDensity.compact,
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
        isThreeLine: true,
        trailing: procesando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    key: ValueKey('equipo_editar_${equipo.id}'),
                    tooltip: 'Editar equipo',
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    key: ValueKey('equipo_cambiar_estado_${equipo.id}'),
                    tooltip: equipo.activo
                        ? 'Dar de baja equipo'
                        : 'Reactivar equipo',
                    onPressed: onCambiarEstado,
                    icon: Icon(equipo.activo ? Icons.block : Icons.restore),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  const _BannerError({required this.mensaje});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('equipos_error_banner'),
      width: double.infinity,
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje ?? 'No se pudo actualizar el listado.',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
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
    );
  }
}

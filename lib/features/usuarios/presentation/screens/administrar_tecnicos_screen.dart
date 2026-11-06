import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/tecnico.dart';
import '../../domain/repositories/usuarios_repository.dart';
import '../../domain/usecases/cambiar_estado_tecnico_usecase.dart';
import '../../domain/usecases/editar_tecnico_usecase.dart';
import '../../domain/usecases/listar_tecnicos_usecase.dart';
import '../providers/administrar_tecnicos_provider.dart';
import 'editar_tecnico_screen.dart';

class AdministrarTecnicosScreen extends StatelessWidget {
  const AdministrarTecnicosScreen({
    super.key,
    this.listarUseCase,
    this.cambiarEstadoUseCase,
    this.editarUseCase,
  });

  final ListarTecnicosUseCase? listarUseCase;
  final CambiarEstadoTecnicoUseCase? cambiarEstadoUseCase;
  final EditarTecnicoUseCase? editarUseCase;

  @override
  Widget build(BuildContext context) {
    final UsuariosRepository? repository =
        listarUseCase == null ||
            cambiarEstadoUseCase == null ||
            editarUseCase == null
        ? context.read<UsuariosRepository>()
        : null;

    return ChangeNotifierProvider(
      create: (_) => AdministrarTecnicosProvider(
        listarTecnicosUseCase:
            listarUseCase ?? ListarTecnicosUseCase(repository!),
        cambiarEstadoTecnicoUseCase:
            cambiarEstadoUseCase ?? CambiarEstadoTecnicoUseCase(repository!),
      ),
      child: _AdministrarTecnicosView(
        editarUseCase: editarUseCase ?? EditarTecnicoUseCase(repository!),
      ),
    );
  }
}

class _AdministrarTecnicosView extends StatefulWidget {
  const _AdministrarTecnicosView({required this.editarUseCase});

  final EditarTecnicoUseCase editarUseCase;

  @override
  State<_AdministrarTecnicosView> createState() =>
      _AdministrarTecnicosViewState();
}

class _AdministrarTecnicosViewState extends State<_AdministrarTecnicosView> {
  final _busquedaController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdministrarTecnicosProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  void _onBuscar(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<AdministrarTecnicosProvider>().buscar(value);
    });
  }

  Future<void> _editar(Tecnico tecnico) async {
    final actualizado = await Navigator.of(context).push<Tecnico>(
      MaterialPageRoute<Tecnico>(
        builder: (_) => EditarTecnicoScreen(
          tecnico: tecnico,
          useCase: widget.editarUseCase,
        ),
      ),
    );
    if (actualizado == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Técnico actualizado correctamente')),
    );
    await context.read<AdministrarTecnicosProvider>().cargar();
  }

  Future<void> _cambiarEstado(Tecnico tecnico, bool activo) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('confirmar_estado_dialog'),
        title: Text(activo ? 'Reactivar técnico' : 'Desactivar técnico'),
        content: Text(
          activo
              ? 'La cuenta de ${tecnico.nombreCompleto} podrá iniciar sesión '
                    'nuevamente.'
              : 'La cuenta de ${tecnico.nombreCompleto} ya no podrá iniciar '
                    'sesión. Sus incidencias atendidas se conservarán.',
        ),
        actions: [
          TextButton(
            key: const Key('confirmar_estado_cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar_estado_aceptar'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(activo ? 'Reactivar' : 'Desactivar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final provider = context.read<AdministrarTecnicosProvider>();
    final ok = await provider.cambiarEstado(tecnico, activo: activo);
    if (!mounted) return;

    final mensaje = ok
        ? (activo ? 'Técnico reactivado' : 'Técnico desactivado')
        : (provider.errorMessage ?? 'No se pudo actualizar la cuenta');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdministrarTecnicosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Administrar soporte')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('buscar_tecnicos_field'),
              controller: _busquedaController,
              textInputAction: TextInputAction.search,
              onChanged: _onBuscar,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _busquedaController.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('limpiar_busqueda_tecnicos'),
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() {});
                          provider.buscar('');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final filtro in FiltroEstadoTecnicos.values)
                  ChoiceChip(
                    key: Key('filtro_tecnicos_${filtro.name}'),
                    label: Text(filtro.etiqueta),
                    selected: provider.filtro == filtro,
                    onSelected: (_) => provider.cambiarFiltro(filtro),
                  ),
              ],
            ),
          ),
          Expanded(child: _contenido(provider)),
        ],
      ),
    );
  }

  Widget _contenido(AdministrarTecnicosProvider provider) {
    if (provider.isLoading && provider.tecnicos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(key: Key('tecnicos_loading')),
      );
    }

    if (provider.hasError && provider.tecnicos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage ?? 'No se pudieron cargar los técnicos.',
                key: const Key('tecnicos_error'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('tecnicos_reintentar'),
                onPressed: provider.cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.busqueda.isEmpty
                ? 'Aún no hay técnicos registrados'
                : 'No se encontraron técnicos',
            key: const Key('tecnicos_vacio'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: provider.tecnicos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final tecnico = provider.tecnicos[index];
          return _TecnicoTile(
            tecnico: tecnico,
            cambiando: provider.isCambiandoEstado(tecnico),
            deshabilitado: provider.hayCambioEnCurso,
            onEditar: () => _editar(tecnico),
            onCambiarEstado: (activo) => _cambiarEstado(tecnico, activo),
          );
        },
      ),
    );
  }
}

class _TecnicoTile extends StatelessWidget {
  const _TecnicoTile({
    required this.tecnico,
    required this.cambiando,
    required this.deshabilitado,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  final Tecnico tecnico;
  final bool cambiando;
  final bool deshabilitado;
  final VoidCallback onEditar;
  final ValueChanged<bool> onCambiarEstado;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: Key('tecnico_item_${tecnico.id}'),
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: tecnico.activo
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.support_agent,
            color: tecnico.activo
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(tecnico.nombreCompleto),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tecnico.correo.isEmpty ? 'Sin correo' : tecnico.correo),
            Text('Usuario: ${tecnico.usuario}'),
            const SizedBox(height: 4),
            _EstadoChip(activo: tecnico.activo),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cambiando)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  key: Key('tecnico_estado_loading'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Switch(
                key: Key('tecnico_switch_${tecnico.id}'),
                value: tecnico.activo,
                onChanged: deshabilitado ? null : onCambiarEstado,
              ),
            IconButton(
              key: Key('tecnico_editar_${tecnico.id}'),
              tooltip: 'Editar técnico',
              icon: const Icon(Icons.edit_outlined),
              onPressed: deshabilitado ? null : onEditar,
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: activo
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 12,
          color: activo
              ? colorScheme.onPrimaryContainer
              : colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

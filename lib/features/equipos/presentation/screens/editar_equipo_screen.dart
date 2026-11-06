import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/edicion_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/repositories/equipos_repository.dart';
import '../../domain/usecases/actualizar_equipo_usecase.dart';
import '../../domain/usecases/obtener_equipo_usecase.dart';
import '../providers/editar_equipo_provider.dart';

class EditarEquipoScreen extends StatelessWidget {
  const EditarEquipoScreen({
    super.key,
    required this.equipoId,
    this.equipoInicial,
    this.obtenerEquipoUseCase,
    this.actualizarEquipoUseCase,
  });

  final int equipoId;
  final Equipo? equipoInicial;
  final ObtenerEquipoUseCase? obtenerEquipoUseCase;
  final ActualizarEquipoUseCase? actualizarEquipoUseCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final repository =
            obtenerEquipoUseCase == null || actualizarEquipoUseCase == null
            ? context.read<EquiposRepository>()
            : null;
        return EditarEquipoProvider(
          equipoId: equipoId,
          equipoInicial: equipoInicial,
          obtenerEquipoUseCase:
              obtenerEquipoUseCase ?? ObtenerEquipoUseCase(repository!),
          actualizarEquipoUseCase:
              actualizarEquipoUseCase ?? ActualizarEquipoUseCase(repository!),
        )..cargar();
      },
      child: const _EditarEquipoBody(),
    );
  }
}

class _EditarEquipoBody extends StatelessWidget {
  const _EditarEquipoBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarEquipoProvider>();
    final equipo = provider.equipo;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar equipo')),
      body: _contenido(provider, equipo),
    );
  }

  Widget _contenido(EditarEquipoProvider provider, Equipo? equipo) {
    if (equipo == null && provider.cargando) {
      return const Center(
        child: CircularProgressIndicator(key: Key('editar_equipo_cargando')),
      );
    }

    if (equipo == null) {
      return _ErrorCarga(
        mensaje:
            provider.errorCarga ??
            'No se pudo cargar el equipo. Inténtalo de nuevo.',
        onReintentar: provider.cargar,
      );
    }

    return _EditarEquipoForm(equipo: equipo);
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
              key: const Key('editar_equipo_error'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const Key('editar_equipo_reintentar'),
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditarEquipoForm extends StatefulWidget {
  const _EditarEquipoForm({required this.equipo});

  final Equipo equipo;

  @override
  State<_EditarEquipoForm> createState() => _EditarEquipoFormState();
}

class _EditarEquipoFormState extends State<_EditarEquipoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(
      text: widget.equipo.identificador,
    );
    _nombreController = TextEditingController(text: widget.equipo.nombre ?? '');
    _ubicacionController = TextEditingController(text: widget.equipo.ubicacion);
    _descripcionController = TextEditingController(
      text: widget.equipo.descripcion ?? '',
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _ubicacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<EditarEquipoProvider>();
    final solicitud = SolicitudEdicionEquipo(
      codigo: _codigoController.text,
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      ubicacion: _ubicacionController.text,
    );

    final ok = await provider.guardar(solicitud);
    if (!mounted) return;
    if (!ok) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('equipo_actualizado_dialog'),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Equipo actualizado'),
        content: Text(
          'Los cambios del equipo ${solicitud.codigoNormalizado} se '
          'guardaron correctamente.',
        ),
        actions: [
          TextButton(
            key: const Key('equipo_actualizado_aceptar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarEquipoProvider>();
    final guardando = provider.guardando;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.edit_note, size: 56, color: Colors.deepPurple),
                const SizedBox(height: 8),
                Text(
                  'Datos del equipo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (provider.errorCarga != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.errorCarga!,
                    key: const Key('editar_equipo_error_actualizacion'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  key: const Key('editar_equipo_codigo_field'),
                  controller: _codigoController,
                  enabled: !guardando,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Identificador del equipo',
                    prefixIcon: Icon(Icons.tag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      SolicitudEdicionEquipo.validarCodigo(value ?? ''),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('editar_equipo_nombre_field'),
                  controller: _nombreController,
                  enabled: !guardando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (opcional)',
                    helperText: 'Si se deja vacío se usará el identificador.',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('editar_equipo_ubicacion_field'),
                  controller: _ubicacionController,
                  enabled: !guardando,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación dentro del laboratorio',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      SolicitudEdicionEquipo.validarUbicacion(value ?? ''),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('editar_equipo_descripcion_field'),
                  controller: _descripcionController,
                  enabled: !guardando,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Descripción (marca o modelo)',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (provider.errorGuardado != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    key: const Key('editar_equipo_error'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.errorGuardado!,
                            key: const Key('editar_equipo_error_message'),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('editar_equipo_guardar'),
                  onPressed: guardando ? null : _submit,
                  child: guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

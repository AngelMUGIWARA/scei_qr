import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/repositories/equipos_repository.dart';
import '../../domain/usecases/registrar_equipo_usecase.dart';
import '../providers/registrar_equipo_provider.dart';

class RegistrarEquipoScreen extends StatelessWidget {
  const RegistrarEquipoScreen({super.key, this.useCase});

  final RegistrarEquipoUseCase? useCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrarEquipoProvider(
        registrarEquipoUseCase:
            useCase ??
            RegistrarEquipoUseCase(context.read<EquiposRepository>()),
      ),
      child: const _RegistrarEquipoForm(),
    );
  }
}

class _RegistrarEquipoForm extends StatefulWidget {
  const _RegistrarEquipoForm();

  @override
  State<_RegistrarEquipoForm> createState() => _RegistrarEquipoFormState();
}

class _RegistrarEquipoFormState extends State<_RegistrarEquipoForm> {
  final _formKey = GlobalKey<FormState>();
  final _identificadorController = TextEditingController();
  final _laboratorioController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _identificadorFocus = FocusNode();

  @override
  void dispose() {
    _identificadorController.dispose();
    _laboratorioController.dispose();
    _ubicacionController.dispose();
    _descripcionController.dispose();
    _identificadorFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<RegistrarEquipoProvider>();
    final solicitud = SolicitudAltaEquipo(
      identificador: _identificadorController.text,
      laboratorio: _laboratorioController.text,
      ubicacion: _ubicacionController.text,
      descripcion: _descripcionController.text,
    );

    final ok = await provider.registrar(solicitud);
    if (!mounted) return;

    if (!ok) {
      if (provider.campoError == 'identificador') {
        _identificadorFocus.requestFocus();
      }
      return;
    }

    await _mostrarConfirmacion(provider.equipo!);
  }

  Future<void> _mostrarConfirmacion(Equipo equipo) async {
    final provider = context.read<RegistrarEquipoProvider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('equipo_registrado_dialog'),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Equipo registrado'),
        content: Text(
          'El equipo ${equipo.identificador} quedó registrado con estado '
          'Activo.',
        ),
        actions: [
          TextButton(
            key: const Key('equipo_registrado_aceptar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _limpiarFormulario();
    provider.reset();
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _identificadorController.clear();
    _laboratorioController.clear();
    _ubicacionController.clear();
    _descripcionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrarEquipoProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar equipo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.computer,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alta de equipo de cómputo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registro de computadoras de los laboratorios.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('equipo_identificador_field'),
                    controller: _identificadorController,
                    focusNode: _identificadorFocus,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Identificador del equipo',
                      prefixIcon: Icon(Icons.tag_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudAltaEquipo.validarIdentificador(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('equipo_laboratorio_field'),
                    controller: _laboratorioController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Laboratorio',
                      prefixIcon: Icon(Icons.science_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudAltaEquipo.validarLaboratorio(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('equipo_ubicacion_field'),
                    controller: _ubicacionController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación dentro del laboratorio',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudAltaEquipo.validarUbicacion(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('equipo_descripcion_field'),
                    controller: _descripcionController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Descripción (marca o modelo)',
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => provider.clearError(),
                  ),
                  if (provider.status == RegistroEquipoStatus.error &&
                      provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: const Key('registrar_equipo_error'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              key: const Key('registrar_equipo_error_message'),
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
                    key: const Key('registrar_equipo_button'),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrar equipo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/edicion_tecnico.dart';
import '../../../../dominio/tecnico.dart';
import '../../domain/repositories/usuarios_repository.dart';
import '../../domain/usecases/editar_tecnico_usecase.dart';
import '../providers/editar_tecnico_provider.dart';

class EditarTecnicoScreen extends StatelessWidget {
  const EditarTecnicoScreen({super.key, required this.tecnico, this.useCase});

  final Tecnico tecnico;
  final EditarTecnicoUseCase? useCase;

  @override
  Widget build(BuildContext context) {
    final useCase =
        this.useCase ??
        EditarTecnicoUseCase(context.read<UsuariosRepository>());

    return ChangeNotifierProvider(
      create: (_) => EditarTecnicoProvider(editarTecnicoUseCase: useCase),
      child: _EditarTecnicoForm(tecnico: tecnico),
    );
  }
}

class _EditarTecnicoForm extends StatefulWidget {
  const _EditarTecnicoForm({required this.tecnico});

  final Tecnico tecnico;

  @override
  State<_EditarTecnicoForm> createState() => _EditarTecnicoFormState();
}

class _EditarTecnicoFormState extends State<_EditarTecnicoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;
  final _passwordController = TextEditingController();
  final _confirmacionController = TextEditingController();
  final _correoFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.tecnico.nombreCompleto,
    );
    _correoController = TextEditingController(text: widget.tecnico.correo);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmacionController.dispose();
    _correoFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<EditarTecnicoProvider>();
    final contrasenaNueva = _passwordController.text;

    final solicitud = SolicitudEdicionTecnico(
      nombreCompleto: _nombreController.text,
      correo: _correoController.text,
      contrasenaNueva: contrasenaNueva.isEmpty ? null : contrasenaNueva,
    );

    final actualizado = await provider.editar(widget.tecnico.id, solicitud);
    if (!mounted) return;

    if (actualizado == null) {
      if (provider.campoError == 'correo') {
        _correoFocus.requestFocus();
      }
      return;
    }

    Navigator.of(context).pop(actualizado);
  }

  String? _validarConfirmacion(String? value) {
    final nueva = _passwordController.text;
    if (nueva.isEmpty) return null;
    if (value == null || value.isEmpty) {
      return 'Confirma la nueva contraseña';
    }
    if (value != nueva) return 'Las contraseñas no coinciden';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarTecnicoProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar técnico')),
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
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(widget.tecnico.usuario),
                      subtitle: Text(
                        widget.tecnico.activo
                            ? 'Cuenta activa'
                            : 'Cuenta inactiva',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('editar_tecnico_nombre_field'),
                    controller: _nombreController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudEdicionTecnico.validarNombreCompleto(
                          value ?? '',
                        ),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('editar_tecnico_correo_field'),
                    controller: _correoController,
                    focusNode: _correoFocus,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudEdicionTecnico.validarCorreo(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Restablecer contraseña',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Déjalo vacío para conservar la contraseña actual.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('editar_tecnico_password_field'),
                    controller: _passwordController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña (opcional)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        SolicitudEdicionTecnico.validarContrasenaNueva(
                          value ?? '',
                        ),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('editar_tecnico_confirmacion_field'),
                    controller: _confirmacionController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarConfirmacion,
                    onChanged: (_) => provider.clearError(),
                  ),
                  if (provider.status == EditarTecnicoStatus.error &&
                      provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: const Key('editar_tecnico_error'),
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
                              key: const Key('editar_tecnico_error_message'),
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
                    key: const Key('editar_tecnico_button'),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
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
      ),
    );
  }
}

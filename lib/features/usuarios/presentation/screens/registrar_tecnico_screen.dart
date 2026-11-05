import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/alta_tecnico.dart';
import '../../../../dominio/tecnico.dart';
import '../../domain/repositories/usuarios_repository.dart';
import '../../domain/usecases/registrar_tecnico_usecase.dart';
import '../providers/registrar_tecnico_provider.dart';

class RegistrarTecnicoScreen extends StatelessWidget {
  const RegistrarTecnicoScreen({super.key, this.useCase});

  final RegistrarTecnicoUseCase? useCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrarTecnicoProvider(
        registrarTecnicoUseCase:
            useCase ??
            RegistrarTecnicoUseCase(context.read<UsuariosRepository>()),
      ),
      child: const _RegistrarTecnicoForm(),
    );
  }
}

class _RegistrarTecnicoForm extends StatefulWidget {
  const _RegistrarTecnicoForm();

  @override
  State<_RegistrarTecnicoForm> createState() => _RegistrarTecnicoFormState();
}

class _RegistrarTecnicoFormState extends State<_RegistrarTecnicoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmacionController = TextEditingController();
  final _correoFocus = FocusNode();
  final _usuarioFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    _confirmacionController.dispose();
    _correoFocus.dispose();
    _usuarioFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<RegistrarTecnicoProvider>();
    final solicitud = SolicitudAltaTecnico(
      nombreCompleto: _nombreController.text,
      correo: _correoController.text,
      usuario: _usuarioController.text,
      contrasenaInicial: _passwordController.text,
    );

    final ok = await provider.registrar(solicitud);
    if (!mounted) return;

    if (!ok) {
      switch (provider.campoError) {
        case 'correo':
          _correoFocus.requestFocus();
        case 'usuario':
          _usuarioFocus.requestFocus();
      }
      return;
    }

    await _mostrarConfirmacion(provider.tecnico!);
  }

  Future<void> _mostrarConfirmacion(Tecnico tecnico) async {
    final provider = context.read<RegistrarTecnicoProvider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('registro_exitoso_dialog'),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Técnico registrado'),
        content: Text(
          'La cuenta de ${tecnico.nombreCompleto} se creó correctamente '
          'con el usuario ${tecnico.usuario}.',
        ),
        actions: [
          TextButton(
            key: const Key('registro_exitoso_aceptar'),
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
    _nombreController.clear();
    _correoController.clear();
    _usuarioController.clear();
    _passwordController.clear();
    _confirmacionController.clear();
    setState(() => _obscurePassword = true);
  }

  String? _validarConfirmacion(String? value) {
    if (value == null || value.isEmpty) return 'Confirma la contraseña';
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrarTecnicoProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar técnico')),
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
                    Icons.person_add_alt_1,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alta de personal de soporte',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La cuenta podrá iniciar sesión en la aplicación móvil '
                    'con el rol Soporte técnico.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('tecnico_nombre_field'),
                    controller: _nombreController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudAltaTecnico.validarNombreCompleto(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('tecnico_correo_field'),
                    controller: _correoController,
                    focusNode: _correoFocus,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudAltaTecnico.validarCorreo(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('tecnico_usuario_field'),
                    controller: _usuarioController,
                    focusNode: _usuarioFocus,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        SolicitudAltaTecnico.validarUsuario(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('tecnico_password_field'),
                    controller: _passwordController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Contraseña inicial',
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
                        SolicitudAltaTecnico.validarContrasena(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('tecnico_confirmacion_field'),
                    controller: _confirmacionController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarConfirmacion,
                    onChanged: (_) => provider.clearError(),
                  ),
                  if (provider.status == RegistroTecnicoStatus.error &&
                      provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: const Key('registrar_tecnico_error'),
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
                              key: const Key('registrar_tecnico_error_message'),
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
                    key: const Key('registrar_tecnico_button'),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrar técnico'),
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

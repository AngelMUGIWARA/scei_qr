import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/alta_alumno.dart';
import '../../../../dominio/alumno.dart';
import '../../domain/repositories/alumnos_repository.dart';
import '../../domain/usecases/registrar_alumno_usecase.dart';
import '../providers/registrar_alumno_provider.dart';

class RegistrarAlumnoScreen extends StatelessWidget {
  const RegistrarAlumnoScreen({super.key, this.useCase});

  final RegistrarAlumnoUseCase? useCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrarAlumnoProvider(
        registrarAlumnoUseCase:
            useCase ??
            RegistrarAlumnoUseCase(context.read<AlumnosRepository>()),
      ),
      child: const _RegistrarAlumnoForm(),
    );
  }
}

class _RegistrarAlumnoForm extends StatefulWidget {
  const _RegistrarAlumnoForm();

  @override
  State<_RegistrarAlumnoForm> createState() => _RegistrarAlumnoFormState();
}

class _RegistrarAlumnoFormState extends State<_RegistrarAlumnoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmacionController = TextEditingController();
  final _matriculaFocus = FocusNode();
  final _correoFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _matriculaController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmacionController.dispose();
    _matriculaFocus.dispose();
    _correoFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<RegistrarAlumnoProvider>();
    final solicitud = SolicitudAltaAlumno(
      nombre: _nombreController.text,
      matricula: _matriculaController.text,
      correoInstitucional: _correoController.text,
      contrasenaInicial: _passwordController.text,
    );

    final ok = await provider.registrar(solicitud);
    if (!mounted) return;

    if (!ok) {
      switch (provider.campoError) {
        case 'matricula':
          _matriculaFocus.requestFocus();
        case 'correo':
        case 'usuario':
          _correoFocus.requestFocus();
      }
      return;
    }

    await _mostrarConfirmacion(provider.alumno!);
  }

  Future<void> _mostrarConfirmacion(Alumno alumno) async {
    final provider = context.read<RegistrarAlumnoProvider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('alumno_registrado_dialog'),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Alumno registrado'),
        content: Text(
          'La cuenta de ${alumno.nombre} quedó activa con la matrícula '
          '${alumno.matricula}.',
        ),
        actions: [
          TextButton(
            key: const Key('alumno_registrado_aceptar'),
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
    _matriculaController.clear();
    _correoController.clear();
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
    final provider = context.watch<RegistrarAlumnoProvider>();
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar alumno')),
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
                  const Icon(Icons.school, size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 12),
                  Text(
                    'Alta de cuenta de alumno',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La cuenta podrá iniciar sesión con el correo '
                    'institucional y la contraseña inicial.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('alumno_nombre_field'),
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
                    validator: (value) => Alumno.validarNombre(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('alumno_matricula_field'),
                    controller: _matriculaController,
                    focusNode: _matriculaFocus,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    decoration: const InputDecoration(
                      labelText: 'Matrícula',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => Alumno.validarMatricula(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('alumno_correo_field'),
                    controller: _correoController,
                    focusNode: _correoFocus,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        Alumno.validarCorreoInstitucional(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('alumno_password_field'),
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
                    validator: (value) => Alumno.validarContrasena(value ?? ''),
                    onChanged: (_) => provider.clearError(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('alumno_confirmacion_field'),
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
                  if (provider.status == RegistroAlumnoStatus.error &&
                      provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      key: const Key('registrar_alumno_error'),
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
                              key: const Key('registrar_alumno_error_message'),
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
                    key: const Key('registrar_alumno_button'),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrar alumno'),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/equipo.dart';
import '../../../usos/domain/repositories/usos_repository.dart';
import '../../../usos/domain/usecases/iniciar_uso_usecase.dart';
import '../providers/registrar_uso_provider.dart';

class ConfirmarUsoScreen extends StatelessWidget {
  const ConfirmarUsoScreen({
    super.key,
    required this.equipo,
    required this.qrToken,
    this.iniciarUsoUseCase,
  });

  final Equipo equipo;
  final String qrToken;
  final IniciarUsoUseCase? iniciarUsoUseCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final useCase =
            iniciarUsoUseCase ??
            IniciarUsoUseCase(context.read<UsosRepository>());
        return RegistrarUsoProvider(
          iniciarUsoUseCase: useCase,
          equipo: equipo,
          qrToken: qrToken,
        );
      },
      child: const _ConfirmarUsoBody(),
    );
  }
}

class _ConfirmarUsoBody extends StatelessWidget {
  const _ConfirmarUsoBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RegistrarUsoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar uso')),
      body: _contenido(context, provider),
    );
  }

  Widget _contenido(BuildContext context, RegistrarUsoProvider provider) {
    switch (provider.status) {
      case RegistroUsoStatus.confirmando:
        return _Confirmar(
          key: const Key('confirmar_uso_confirmando'),
          equipo: provider.equipo,
          onConfirmar: provider.confirmar,
          onCancelar: () => Navigator.of(context).pop(),
        );

      case RegistroUsoStatus.registrando:
        return const Center(
          key: Key('confirmar_uso_registrando'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Registrando uso…'),
            ],
          ),
        );

      case RegistroUsoStatus.registrado:
        return _Registrado(
          key: const Key('confirmar_uso_registrado'),
          equipo: provider.equipo,
          inicio: provider.uso?.inicio,
          onListo: () => Navigator.of(context).pop(),
        );

      case RegistroUsoStatus.error:
        return _ErrorRegistro(
          key: const Key('confirmar_uso_error'),
          mensaje: provider.error ?? 'No se pudo registrar el uso.',
          reintentable: provider.reintentable,
          onReintentar: provider.reintentar,
          onVolver: () => Navigator.of(context).pop(),
        );
    }
  }
}

class _Confirmar extends StatelessWidget {
  const _Confirmar({
    super.key,
    required this.equipo,
    required this.onConfirmar,
    required this.onCancelar,
  });

  final Equipo equipo;
  final Future<void> Function() onConfirmar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            Text(
              'Equipo identificado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _TarjetaEquipo(equipo: equipo),
            const SizedBox(height: 16),
            const Text(
              'Se registrará tu uso con la fecha y hora actual.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('confirmar_uso_confirmar'),
              onPressed: () => onConfirmar(),
              icon: const Icon(Icons.check),
              label: const Text('Confirmar uso'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('confirmar_uso_cancelar'),
              onPressed: onCancelar,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Registrado extends StatelessWidget {
  const _Registrado({
    super.key,
    required this.equipo,
    required this.inicio,
    required this.onListo,
  });

  final Equipo equipo;
  final DateTime? inicio;
  final VoidCallback onListo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            Text(
              'Uso registrado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _TarjetaEquipo(equipo: equipo),
            if (inicio != null) ...[
              const SizedBox(height: 12),
              Text(
                'Inicio: ${_formatearFechaHora(inicio!)}',
                key: const Key('confirmar_uso_registrado_inicio'),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('confirmar_uso_listo'),
              onPressed: onListo,
              icon: const Icon(Icons.done),
              label: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRegistro extends StatelessWidget {
  const _ErrorRegistro({
    super.key,
    required this.mensaje,
    required this.reintentable,
    required this.onReintentar,
    required this.onVolver,
  });

  final String mensaje;
  final bool reintentable;
  final Future<void> Function() onReintentar;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'No se pudo registrar el uso',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              key: const Key('confirmar_uso_error_mensaje'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (reintentable)
              FilledButton.icon(
                key: const Key('confirmar_uso_reintentar'),
                onPressed: () => onReintentar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('confirmar_uso_volver'),
              onPressed: onVolver,
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaEquipo extends StatelessWidget {
  const _TarjetaEquipo({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.computer, size: 48),
            const SizedBox(height: 8),
            Text(
              equipo.identificador,
              key: const Key('confirmar_uso_equipo_identificador'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (equipo.nombreVisible != equipo.identificador) ...[
              const SizedBox(height: 4),
              Text(
                equipo.nombreVisible,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.outline),
              ),
            ],
            const SizedBox(height: 12),
            Text('Ubicación: ${equipo.ubicacion}', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatearFechaHora(DateTime valor) {
  final local = valor.toLocal();
  String dos(int numero) => numero.toString().padLeft(2, '0');
  return '${dos(local.day)}/${dos(local.month)}/${local.year} '
      '${dos(local.hour)}:${dos(local.minute)}';
}

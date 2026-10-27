import 'package:flutter/material.dart';

class PantallaAccesoDenegado extends StatelessWidget {
  const PantallaAccesoDenegado({
    super.key,
    required this.motivo,
    this.alVolver,
  });

  final String motivo;
  final VoidCallback? alVolver;

  @override
  Widget build(BuildContext context) {
    final puedeVolver = alVolver != null || Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(title: const Text('Acceso restringido')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              Text(
                motivo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (puedeVolver) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: alVolver ?? () => Navigator.of(context).maybePop(),
                  child: const Text('Volver'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

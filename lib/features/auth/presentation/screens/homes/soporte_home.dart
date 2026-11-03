import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../dominio/sesion.dart';
import '../../providers/auth_provider.dart';
import '../../rol_ui.dart';

/// Pantalla principal de **Soporte técnico** (placeholder de la Iteración 1).
class SoporteHome extends StatelessWidget {
  const SoporteHome({super.key});

  @override
  Widget build(BuildContext context) {
    final Sesion session = context.watch<AuthProvider>().session!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte técnico'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(session.nombreCompleto)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(session.nombreCompleto),
              subtitle: Text('${session.rol.etiqueta} · ${session.username}'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Próximamente (Iteración 3):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const ListTile(
            leading: Icon(Icons.inbox),
            title: Text('Incidencias reportadas'),
            subtitle: Text('HU-ST-02'),
          ),
          const ListTile(
            leading: Icon(Icons.play_circle),
            title: Text('Tomar una incidencia'),
            subtitle: Text('HU-ST-04'),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle),
            title: Text('Registrar solución'),
            subtitle: Text('HU-ST-06'),
          ),
        ],
      ),
    );
  }
}

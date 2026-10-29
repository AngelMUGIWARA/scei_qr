import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../dominio/sesion.dart';
import '../../providers/auth_provider.dart';
import '../../rol_ui.dart';

/// Pantalla principal del **Administrador** (placeholder de la Iteración 1).
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final Sesion session = context.watch<AuthProvider>().session!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador'),
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
            'Próximamente (Iteración 1 y 4):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const ListTile(
            leading: Icon(Icons.support_agent),
            title: Text('Registrar personal de soporte'),
            subtitle: Text('HU-AD-02'),
          ),
          const ListTile(
            leading: Icon(Icons.computer),
            title: Text('Registrar equipos de cómputo'),
            subtitle: Text('HU-AD-04'),
          ),
          const ListTile(
            leading: Icon(Icons.qr_code),
            title: Text('Generar código QR'),
            subtitle: Text('HU-AD-06'),
          ),
        ],
      ),
    );
  }
}

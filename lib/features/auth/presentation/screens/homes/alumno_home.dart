import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../dominio/sesion.dart';
import '../../providers/auth_provider.dart';
import '../../rol_ui.dart';

/// Pantalla principal del **Alumno** (placeholder de la Iteración 1).
///
/// Muestra la sesión activa y deja visibles las funciones que llegarán en
/// las HU-AL-02 a HU-AL-07.
class AlumnoHome extends StatelessWidget {
  const AlumnoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final Sesion session = context.watch<AuthProvider>().session!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumno'),
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
            'Próximamente (Iteración 1 y 2):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const ListTile(
            leading: Icon(Icons.qr_code_scanner),
            title: Text('Escanear código QR'),
            subtitle: Text('HU-AL-02'),
          ),
          const ListTile(
            leading: Icon(Icons.computer),
            title: Text('Registrar uso de un equipo'),
            subtitle: Text('HU-AL-03'),
          ),
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('Consultar mis registros'),
            subtitle: Text('HU-AL-05'),
          ),
        ],
      ),
    );
  }
}

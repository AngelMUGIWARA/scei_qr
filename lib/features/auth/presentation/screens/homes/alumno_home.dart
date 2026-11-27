import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../dominio/permiso.dart';
import '../../../../../dominio/regla_acceso.dart';
import '../../../../../dominio/sesion.dart';
import '../../../../escaneo/presentation/screens/escanear_qr_screen.dart';
import '../../../../usos/presentation/widgets/uso_activo_card.dart';
import '../../providers/auth_provider.dart';
import '../../rol_ui.dart';
import 'boton_cerrar_sesion.dart';

/// Pantalla principal del **Alumno** (placeholder de la Iteración 1).
///
/// Muestra la sesión activa y deja visibles las funciones que llegarán en
/// las HU-AL-03 a HU-AL-07 (HU-AL-02 ya está implementada).
class AlumnoHome extends StatelessWidget {
  const AlumnoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final Sesion session = context.watch<AuthProvider>().session!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumno'),
        actions: [
          const BotonCerrarSesion(),
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
          // HU-AL-04: uso activo con el botón "Finalizar uso".
          const UsoActivoCard(),
          const SizedBox(height: 8),
          const Text(
            'Próximamente (Iteración 2):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // HU-AL-02: escaneo del QR del equipo.
          ListTile(
            key: const Key('alumno_escanear_qr'),
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escanear código QR'),
            subtitle: const Text('Identifica el equipo con su código'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EscanearQrScreen()),
            ),
          ),
          ListTile(
            key: const Key('alumno_registrar_uso'),
            leading: const Icon(Icons.computer),
            title: const Text('Registrar uso de un equipo'),
            subtitle: const Text('Escanea el QR y confirma el registro'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EscanearQrScreen()),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('Consultar mis registros'),
            subtitle: Text('HU-AL-05'),
          ),
          // HU-AL-06: reporte de incidencia del equipo. Se muestra solo
          // con el permiso correspondiente, como el resto del menú.
          if (ReglaAcceso.validar(session.rol, Permiso.reportarIncidencia) ==
              null)
            ListTile(
              key: const Key('alumno_reportar_incidencia'),
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Reportar incidencia'),
              subtitle: const Text('Reporta una falla en la computadora'),
              onTap: () {
                // La pantalla de reporte requiere un equipo ya identificado.
                // Desde el home se llega primero al escaneo; la pantalla de
                // reporte se abre desde allí con el equipo resuelto.
                // El otro punto de entrada es la tarjeta del uso activo
                // (HU-AL-06), que ya trae el equipo del uso en curso.
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EscanearQrScreen(modoReporte: true),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

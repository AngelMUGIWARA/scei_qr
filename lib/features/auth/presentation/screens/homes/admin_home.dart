import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../dominio/permiso.dart';
import '../../../../../dominio/sesion.dart';
import '../../../../../presentacion/acceso/menu_por_rol.dart';
import '../../providers/auth_provider.dart';
import '../../rol_ui.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final Sesion session = context.watch<AuthProvider>().session!;

    final opciones = <OpcionMenu>[
      OpcionMenu(
        titulo: 'Administrar soporte',
        permiso: Permiso.administrarSoporte,
        icono: Icons.support_agent,
        alSeleccionar: () => _proximamente(context, 'Administrar soporte'),
      ),
      OpcionMenu(
        titulo: 'Gestionar alumnos',
        permiso: Permiso.gestionarAlumnos,
        icono: Icons.school,
        alSeleccionar: () => _proximamente(context, 'Gestionar alumnos'),
      ),
      OpcionMenu(
        titulo: 'Administrar equipos',
        permiso: Permiso.administrarEquipos,
        icono: Icons.computer,
        alSeleccionar: () => _proximamente(context, 'Administrar equipos'),
      ),
      OpcionMenu(
        titulo: 'Gestionar códigos QR',
        permiso: Permiso.gestionarQr,
        icono: Icons.qr_code,
        alSeleccionar: () => _proximamente(context, 'Gestionar códigos QR'),
      ),
      OpcionMenu(
        titulo: 'Consultar historial de uso',
        permiso: Permiso.consultarHistorialUso,
        icono: Icons.history,
        alSeleccionar: () =>
            _proximamente(context, 'Consultar historial de uso'),
      ),
      OpcionMenu(
        titulo: 'Supervisar incidencias',
        permiso: Permiso.consultarIncidencias,
        icono: Icons.report_problem,
        alSeleccionar: () => _proximamente(context, 'Supervisar incidencias'),
      ),
      OpcionMenu(
        titulo: 'Consultar estadísticas',
        permiso: Permiso.consultarEstadisticas,
        icono: Icons.bar_chart,
        alSeleccionar: () => _proximamente(context, 'Consultar estadísticas'),
      ),
      OpcionMenu(
        titulo: 'Exportar reportes',
        permiso: Permiso.exportarReportes,
        icono: Icons.download,
        alSeleccionar: () => _proximamente(context, 'Exportar reportes'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(session.nombreCompleto)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(session.nombreCompleto),
                subtitle: Text('${session.rol.etiqueta} · ${session.username}'),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Menú de gestión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: MenuPorRol(
              sesion: session,
              opciones: opciones,
              mensajeVacio: 'No tienes permisos de administración',
            ),
          ),
        ],
      ),
    );
  }

  void _proximamente(BuildContext context, String titulo) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$titulo: próximamente')));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/rol.dart';
import '../../../../../presentacion/acceso/pantalla_acceso_denegado.dart';
import '../../../../../presentacion/acceso/ruta_protegida.dart';
import '../providers/auth_provider.dart';
import '../rol_ui.dart';
import 'homes/admin_home.dart';
import 'homes/alumno_home.dart';
import 'homes/soporte_home.dart';

/// Rutea a la pantalla principal según el rol (HU-GEN-01, lado cliente).
///
/// - Sin sesión (p. ej. el token expiró mientras la app estaba en segundo
///   plano) vuelve al login.
/// - Con sesión, el contenido queda protegido por [RutaProtegida]: valida
///   vigencia y permiso del rol con `ReglaAcceso`, que es la **única**
///   matriz de permisos de la app (el chequeo por rol no se duplica en la
///   capa de datos).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (_) => false,
          );
        }
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Widget home = switch (session.rol) {
      Rol.soporteTecnico => const SoporteHome(),
      Rol.administrador => const AdminHome(),
      Rol.alumno => const AlumnoHome(),
    };

    return RutaProtegida(
      sesion: session,
      permiso: session.rol.permisoHome,
      alRechazar: (context, motivo) => PantallaAccesoDenegado(
        motivo: motivo,
        alVolver: () => Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (_) => false,
        ),
      ),
      child: home,
    );
  }
}

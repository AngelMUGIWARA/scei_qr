import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/rol.dart';
import '../providers/auth_provider.dart';
import 'homes/admin_home.dart';
import 'homes/alumno_home.dart';
import 'homes/soporte_home.dart';

/// Rutea a la pantalla principal según el rol (HU-GEN-01, lado cliente).
///
/// Si no hay sesión (p. ej. el token expiró mientras la app estaba en
/// segundo plano) vuelve al login.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;

    if (session == null) {
      // Defensa: sin sesión no hay pantalla interna accesible.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return switch (session.rol) {
      Rol.soporteTecnico => const SoporteHome(),
      Rol.administrador => const AdminHome(),
      Rol.alumno => const AlumnoHome(),
    };
  }
}

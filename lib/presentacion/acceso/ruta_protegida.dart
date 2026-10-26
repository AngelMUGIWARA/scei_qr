import 'package:flutter/material.dart';

import '../../dominio/permiso.dart';
import '../../dominio/regla_acceso.dart';
import '../../dominio/sesion.dart';
import 'pantalla_acceso_denegado.dart';

class RutaProtegida extends StatelessWidget {
  const RutaProtegida({
    super.key,
    required this.sesion,
    required this.permiso,
    required this.child,
    this.ahora,
    this.alRechazar,
  });

  final Sesion? sesion;
  final Permiso permiso;
  final Widget child;
  final DateTime? ahora;
  final Widget Function(BuildContext context, String motivo)? alRechazar;

  @override
  Widget build(BuildContext context) {
    final motivo = ReglaAcceso.validarSesion(
      sesion,
      permiso,
      ahora ?? DateTime.now(),
    );

    if (motivo == null) return child;

    return alRechazar?.call(context, motivo) ??
        PantallaAccesoDenegado(motivo: motivo);
  }
}

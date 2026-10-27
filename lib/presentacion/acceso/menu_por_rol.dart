import 'package:flutter/material.dart';

import '../../dominio/permiso.dart';
import '../../dominio/regla_acceso.dart';
import '../../dominio/sesion.dart';

class OpcionMenu {
  const OpcionMenu({
    required this.titulo,
    required this.permiso,
    required this.icono,
    required this.alSeleccionar,
  });

  final String titulo;
  final Permiso permiso;
  final IconData icono;
  final VoidCallback alSeleccionar;
}

List<OpcionMenu> opcionesPermitidas({
  required Iterable<OpcionMenu> opciones,
  required Sesion? sesion,
  DateTime? ahora,
}) {
  final momento = ahora ?? DateTime.now();
  return opciones
      .where(
        (opcion) =>
            ReglaAcceso.validarSesion(sesion, opcion.permiso, momento) == null,
      )
      .toList(growable: false);
}

class MenuPorRol extends StatelessWidget {
  const MenuPorRol({
    super.key,
    required this.sesion,
    required this.opciones,
    this.ahora,
    this.mensajeVacio = 'No hay opciones disponibles para tu rol',
  });

  final Sesion? sesion;
  final List<OpcionMenu> opciones;
  final DateTime? ahora;
  final String mensajeVacio;

  @override
  Widget build(BuildContext context) {
    final visibles = opcionesPermitidas(
      opciones: opciones,
      sesion: sesion,
      ahora: ahora,
    );

    if (visibles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(mensajeVacio, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      itemCount: visibles.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final opcion = visibles[index];
        return ListTile(
          leading: Icon(opcion.icono),
          title: Text(opcion.titulo),
          trailing: const Icon(Icons.chevron_right),
          onTap: opcion.alSeleccionar,
        );
      },
    );
  }
}

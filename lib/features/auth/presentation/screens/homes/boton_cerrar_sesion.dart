import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Opción "Cerrar sesión" compartida por los tres homes (HU-GEN-02).
///
/// Al pulsarla borra el token persistido y pone la sesión en `null`.
/// La navegación de vuelta al login **no** vive aquí: la centraliza
/// [HomeScreen], que observa el `AuthProvider` y limpia la pila de rutas
/// (`pushNamedAndRemoveUntil('/login')`), cumpliendo el CA de no poder volver
/// a las pantallas internas con el botón "atrás".
class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('logout_button'),
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesión',
      onPressed: () => context.read<AuthProvider>().cerrarSesion(),
    );
  }
}

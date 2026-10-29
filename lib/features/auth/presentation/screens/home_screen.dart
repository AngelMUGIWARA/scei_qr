import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/rol.dart';
import '../providers/auth_provider.dart';
import 'homes/admin_home.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;

    if (session == null || session.rol != Rol.administrador) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const AdminHome();
  }
}

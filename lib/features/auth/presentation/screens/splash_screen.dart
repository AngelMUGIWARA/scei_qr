import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../rol_ui.dart';

/// Pantalla de arranque: restaura la sesión y rutea (arquitectura-login-sesion §5).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<AuthProvider>();
    _provider.addListener(_onStatusChanged);
    // Se ejecuta después del primer frame para garantizar los listeners listos.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _provider.restoreSession());
  }

  void _onStatusChanged() {
    if (!mounted) return;
    final session = _provider.session;

    switch (_provider.status) {
      case AuthStatus.authenticated:
        if (session != null) {
          Navigator.of(context).pushReplacementNamed(session.rol.rutaHome);
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        Navigator.of(context).pushReplacementNamed('/login');
        break;
      case AuthStatus.initial:
      case AuthStatus.loading:
        break;
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 72, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'SCEI QR',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/datasources/http_auth_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/cerrar_sesion_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/restore_session_usecase.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/equipos/data/datasources/http_equipos_data_source.dart';
import 'features/equipos/data/repositories/equipos_repository_impl.dart';
import 'features/equipos/domain/repositories/equipos_repository.dart';
import 'features/usuarios/data/datasources/http_usuarios_data_source.dart';
import 'features/usuarios/data/repositories/usuarios_repository_impl.dart';
import 'features/usuarios/domain/repositories/usuarios_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensamblado de dependencias.
  final storage = SecureStorageService();

  final remoteDataSource = HttpAuthDataSource(
    baseUrl: AppConfig.apiBaseUrl,
    client: http.Client(),
  );

  final authRepository = AuthRepositoryImpl(
    remote: remoteDataSource,
    storage: storage,
  );

  final usuariosRepository = UsuariosRepositoryImpl(
    HttpUsuariosDataSource(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: storage.readAccessToken,
      client: http.Client(),
    ),
  );

  // HU-AD-04: alta de equipos de cómputo.
  final equiposRepository = EquiposRepositoryImpl(
    HttpEquiposDataSource(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: storage.readAccessToken,
      client: http.Client(),
    ),
  );

  runApp(
    SceiQrApp(
      authRepository: authRepository,
      usuariosRepository: usuariosRepository,
      equiposRepository: equiposRepository,
    ),
  );
}

class SceiQrApp extends StatelessWidget {
  const SceiQrApp({
    super.key,
    required this.authRepository,
    required this.usuariosRepository,
    required this.equiposRepository,
  });

  final AuthRepository authRepository;
  final UsuariosRepository usuariosRepository;
  final EquiposRepository equiposRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<UsuariosRepository>.value(value: usuariosRepository),
        Provider<EquiposRepository>.value(value: equiposRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(authRepository),
            restoreSessionUseCase: RestoreSessionUseCase(authRepository),
            cerrarSesionUseCase: CerrarSesionUseCase(authRepository),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SCEI QR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          // Home único: el ruteo por rol lo decide HomeScreen (HU-GEN-01).
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

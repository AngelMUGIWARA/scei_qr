import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/alumnos/data/datasources/http_alumnos_data_source.dart';
import 'features/alumnos/data/repositories/alumnos_repository_impl.dart';
import 'features/alumnos/domain/repositories/alumnos_repository.dart';
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
import 'features/usos/data/datasources/http_usos_data_source.dart';
import 'features/usos/data/datasources/local/cola_usos_local_data_source.dart';
import 'features/usos/data/repositories/cola_usos_pendientes_repository_impl.dart';
import 'features/usos/data/repositories/usos_repository_impl.dart';
import 'features/usos/domain/repositories/cola_usos_pendientes_repository.dart';
import 'features/usos/domain/repositories/usos_repository.dart';
import 'features/usos/domain/usecases/sincronizar_usos_pendientes_usecase.dart';
import 'features/usos/presentation/providers/sincronizacion_usos_provider.dart';
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

  // HU-AD-12: alta, baja lógica y conservación del historial de alumnos.
  final alumnosRepository = AlumnosRepositoryImpl(
    HttpAlumnosDataSource(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: storage.readAccessToken,
      client: http.Client(),
    ),
  );

  // HU-AL-03: registro del uso de un equipo.
  final usosRepository = UsosRepositoryImpl(
    HttpUsosDataSource(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: storage.readAccessToken,
      client: http.Client(),
    ),
  );

  // HU-AL-03: cola local para registros sin conexión.
  final colaUsosPendientes = ColaUsosPendientesRepositoryImpl(
    SharedPreferencesColaUsosLocalDataSource(),
  );

  runApp(
    SceiQrApp(
      authRepository: authRepository,
      usuariosRepository: usuariosRepository,
      equiposRepository: equiposRepository,
      alumnosRepository: alumnosRepository,
      usosRepository: usosRepository,
      colaUsosPendientes: colaUsosPendientes,
    ),
  );
}

class SceiQrApp extends StatelessWidget {
  const SceiQrApp({
    super.key,
    required this.authRepository,
    required this.usuariosRepository,
    required this.equiposRepository,
    required this.alumnosRepository,
    required this.usosRepository,
    required this.colaUsosPendientes,
  });

  final AuthRepository authRepository;
  final UsuariosRepository usuariosRepository;
  final EquiposRepository equiposRepository;
  final AlumnosRepository alumnosRepository;
  final UsosRepository usosRepository;
  final ColaUsosPendientesRepository colaUsosPendientes;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<UsuariosRepository>.value(value: usuariosRepository),
        Provider<EquiposRepository>.value(value: equiposRepository),
        Provider<AlumnosRepository>.value(value: alumnosRepository),
        Provider<UsosRepository>.value(value: usosRepository),
        Provider<ColaUsosPendientesRepository>.value(
          value: colaUsosPendientes,
        ),
        ChangeNotifierProvider<SincronizacionUsosProvider>(
          lazy: false,
          create: (_) => SincronizacionUsosProvider(
            sincronizarUseCase: SincronizarUsosPendientesUseCase(
              usosRepository,
              colaUsosPendientes,
            ),
            cola: colaUsosPendientes,
          )..iniciar(),
        ),
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

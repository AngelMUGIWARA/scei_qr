import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/datasources/http_auth_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/restore_session_usecase.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Ensamblado de dependencias (inyección ligera, arquitectura §2) ---
  // El DataSource es una interfaz: para usar un mock basta con sustituir
  // HttpAuthDataSource por MockAuthDataSource aquí, sin tocar UI ni Dominio.
  final storage = SecureStorageService();
  final remoteDataSource = HttpAuthDataSource(
    baseUrl: AppConfig.apiBaseUrl,
    client: http.Client(),
  );
  final authRepository = AuthRepositoryImpl(
    remote: remoteDataSource,
    storage: storage,
  );

  runApp(SceiQrApp(authRepository: authRepository));
}

class SceiQrApp extends StatelessWidget {
  const SceiQrApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            loginUseCase: LoginUseCase(authRepository),
            restoreSessionUseCase: RestoreSessionUseCase(authRepository),
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
          '/home': (_) => const HomeScreen(),
          '/home/alumno': (_) => const HomeScreen(),
          '/home/soporte': (_) => const HomeScreen(),
          '/home/admin': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

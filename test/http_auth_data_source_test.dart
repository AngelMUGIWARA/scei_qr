import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/features/auth/data/datasources/http_auth_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3000/api/v1';

  Map<String, dynamic> cuerpoLogin({String rol = 'ALUMNO'}) => {
    'accessToken': 'jwt',
    'tokenType': 'Bearer',
    'expiresIn': 28800,
    'user': {
      'id': 1,
      'username': 'alumno1',
      'fullName': 'Lucía Fernández',
      'rol': rol,
    },
  };

  group('HttpAuthDataSource.login', () {
    test('200: parsea el contrato real de scei_qr_api', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), '$baseUrl/auth/login');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(jsonDecode(request.body), {
          'username': 'alumno1',
          'password': 'Password123!',
        });
        return http.Response(jsonEncode(cuerpoLogin(rol: 'SOPORTE')), 200);
      });

      final ds = HttpAuthDataSource(baseUrl: baseUrl, client: client);
      final model = await ds.login('alumno1', 'Password123!');

      expect(model.accessToken, 'jwt');
      expect(model.expiresIn, 28800);
      expect(model.rol, 'SOPORTE');
      expect(model.fullName, 'Lucía Fernández');
    });

    test('URL sin barra final construye correctamente el endpoint', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/api/v1/auth/login',
        );
        return http.Response(jsonEncode(cuerpoLogin()), 200);
      });

      final ds = HttpAuthDataSource(
        baseUrl: 'http://localhost:3000/api/v1',
        client: client,
      );

      await ds.login('alumno1', 'Password123!');
    });

    test(
      'URL con una barra final construye correctamente el endpoint',
      () async {
        final client = MockClient((request) async {
          expect(
            request.url.toString(),
            'http://localhost:3000/api/v1/auth/login',
          );
          return http.Response(jsonEncode(cuerpoLogin()), 200);
        });

        final ds = HttpAuthDataSource(
          baseUrl: 'http://localhost:3000/api/v1/',
          client: client,
        );

        await ds.login('alumno1', 'Password123!');
      },
    );

    test(
      'URL con varias barras finales construye correctamente el endpoint',
      () async {
        final client = MockClient((request) async {
          expect(
            request.url.toString(),
            'http://localhost:3000/api/v1/auth/login',
          );
          return http.Response(jsonEncode(cuerpoLogin()), 200);
        });

        final ds = HttpAuthDataSource(
          baseUrl: 'http://localhost:3000/api/v1///',
          client: client,
        );

        await ds.login('alumno1', 'Password123!');
      },
    );

    test('401 lanza AuthException con mensaje genérico (HU-AL-01)', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 401,
            'message': 'Usuario o contraseña incorrectos',
            'error': 'Unauthorized',
          }),
          401,
        ),
      );

      final ds = HttpAuthDataSource(baseUrl: baseUrl, client: client);

      await expectLater(
        ds.login('alumno1', 'mala'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'mensaje',
            'Usuario o contraseña incorrectos',
          ),
        ),
      );
    });

    test('400 (DTO inválido) también usa el mensaje genérico', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 400,
            'message': ['password too short'],
          }),
          400,
        ),
      );

      final ds = HttpAuthDataSource(baseUrl: baseUrl, client: client);

      await expectLater(
        ds.login('alumno1', '123'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'mensaje',
            'Usuario o contraseña incorrectos',
          ),
        ),
      );
    });

    test('500 lanza ServerException', () async {
      final client = MockClient(
        (_) async => http.Response('{"statusCode":500}', 500),
      );

      final ds = HttpAuthDataSource(baseUrl: baseUrl, client: client);

      await expectLater(
        ds.login('alumno1', 'Password123!'),
        throwsA(isA<ServerException>()),
      );
    });

    test('respuesta 200 con body inválido lanza ServerException', () async {
      final client = MockClient((_) async => http.Response('<html>', 200));

      final ds = HttpAuthDataSource(baseUrl: baseUrl, client: client);

      await expectLater(
        ds.login('alumno1', 'Password123!'),
        throwsA(isA<ServerException>()),
      );
    });

    test('sin conexión lanza NetworkException (no AuthException)', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      final ds = HttpAuthDataSource(baseUrl: baseUrl, client: client);

      await expectLater(
        ds.login('alumno1', 'Password123!'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('HttpAuthDataSource - validación de URL', () {
    test('http con host remoto lanza ConfigException', () {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        () => HttpAuthDataSource(
          baseUrl: 'http://api.ejemplo.com/api/v1',
          client: client,
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('http con IP remota lanza ConfigException', () {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        () => HttpAuthDataSource(
          baseUrl: 'http://192.168.1.100:3000/api/v1',
          client: client,
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('http://localhost:3000/api/v1 es permitido', () {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        () => HttpAuthDataSource(
          baseUrl: 'http://localhost:3000/api/v1',
          client: client,
        ),
        returnsNormally,
      );
    });

    test('http://127.0.0.1:3000/api/v1 es permitido', () {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        () => HttpAuthDataSource(
          baseUrl: 'http://127.0.0.1:3000/api/v1',
          client: client,
        ),
        returnsNormally,
      );
    });

    test('http://10.0.2.2:3000/api/v1 es permitido', () {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        () => HttpAuthDataSource(
          baseUrl: 'http://10.0.2.2:3000/api/v1',
          client: client,
        ),
        returnsNormally,
      );
    });

    test('https con cualquier host es permitido', () {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        () => HttpAuthDataSource(
          baseUrl: 'https://api.ejemplo.com/api/v1',
          client: client,
        ),
        returnsNormally,
      );
    });
  });
}

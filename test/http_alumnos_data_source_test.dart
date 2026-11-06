import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_alumno.dart';
import 'package:scei_qr/features/alumnos/data/datasources/http_alumnos_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3000/api/v1';

  final solicitud = const SolicitudAltaAlumno(
    nombre: 'Ana López',
    matricula: '20231234',
    correoInstitucional: 'Ana.Lopez@Universidad.edu.mx',
    contrasenaInicial: 'secreta123',
  );

  Map<String, dynamic> cuerpoAlumno() => {
    'id': 42,
    'username': 'ana.lopez@universidad.edu.mx',
    'fullName': 'Ana López',
    'correo': 'ana.lopez@universidad.edu.mx',
    'matricula': '20231234',
    'rol': 'ALUMNO',
    'activo': true,
    'createdAt': '2026-11-06T12:00:00.000Z',
  };

  HttpAlumnosDataSource datasource(
    http.Client client, {
    TokenProvider? tokenProvider,
  }) {
    return HttpAlumnosDataSource(
      baseUrl: baseUrl,
      tokenProvider: tokenProvider ?? () async => 'jwt-admin',
      client: client,
    );
  }

  group('HttpAlumnosDataSource.registrarAlumno', () {
    test('201: envía el alta con token y rol ALUMNO', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), '$baseUrl/usuarios');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        expect(jsonDecode(request.body), {
          'username': 'ana.lopez@universidad.edu.mx',
          'password': 'secreta123',
          'fullName': 'Ana López',
          'correo': 'ana.lopez@universidad.edu.mx',
          'matricula': '20231234',
          'rol': 'ALUMNO',
        });
        return http.Response(jsonEncode(cuerpoAlumno()), 201);
      });

      final model = await datasource(client).registrarAlumno(solicitud);

      expect(model.id, 42);
      expect(model.username, 'ana.lopez@universidad.edu.mx');
      expect(model.fullName, 'Ana López');
      expect(model.matricula, '20231234');
      expect(model.rol, 'ALUMNO');
      expect(model.activo, isTrue);
      expect(model.fechaAlta, isNotNull);
    });

    test('normaliza la URL base con barras finales', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/usuarios');
        return http.Response(jsonEncode(cuerpoAlumno()), 201);
      });

      final ds = HttpAlumnosDataSource(
        baseUrl: '$baseUrl///',
        tokenProvider: () async => 'jwt-admin',
        client: client,
      );

      await ds.registrarAlumno(solicitud);
    });

    test('201 con rol distinto de ALUMNO produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({...cuerpoAlumno(), 'rol': 'SOPORTE'}),
          201,
        ),
      );

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      '409 de matrícula produce ConflictException con campo matricula',
      () async {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'statusCode': 409,
              'message': 'La matrícula "20231234" ya existe',
              'error': 'Conflict',
            }),
            409,
          ),
        );

        await expectLater(
          datasource(client).registrarAlumno(solicitud),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.campo, 'campo', 'matricula')
                .having(
                  (e) => e.message,
                  'mensaje',
                  'La matrícula "20231234" ya existe',
                ),
          ),
        );
      },
    );

    test('409 de correo produce ConflictException con campo correo', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 409,
            'message': 'El correo "ana.lopez@universidad.edu.mx" ya existe',
            'error': 'Conflict',
          }),
          409,
        ),
      );

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(
          isA<ConflictException>().having((e) => e.campo, 'campo', 'correo'),
        ),
      );
    });

    test(
      '409 de usuario produce ConflictException con campo usuario',
      () async {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'statusCode': 409,
              'message': 'El usuario "ana.lopez@universidad.edu.mx" ya existe',
              'error': 'Conflict',
            }),
            409,
          ),
        );

        await expectLater(
          datasource(client).registrarAlumno(solicitud),
          throwsA(
            isA<ConflictException>().having((e) => e.campo, 'campo', 'usuario'),
          ),
        );
      },
    );

    test('400 convierte la lista de mensajes en ValidationException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 400,
            'message': ['matricula: formato inválido', 'password: muy corta'],
            'error': 'Bad Request',
          }),
          400,
        ),
      );

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'mensaje',
            'matricula: formato inválido password: muy corta',
          ),
        ),
      );
    });

    test('401 produce AuthException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 401, 'message': 'Unauthorized'}),
          401,
        ),
      );

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(isA<AuthException>()),
      );
    });

    test('403 produce ForbiddenException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 403, 'message': 'Forbidden'}),
          403,
        ),
      );

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('500 produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response('{"statusCode":500}', 500),
      );

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(isA<ServerException>()),
      );
    });

    test('201 con cuerpo inválido produce ServerException', () async {
      final client = MockClient((_) async => http.Response('<html>', 201));

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(isA<ServerException>()),
      );
    });

    test('sin token no intenta la petición y lanza AuthException', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response('{}', 201);
      });

      await expectLater(
        datasource(
          client,
          tokenProvider: () async => null,
        ).registrarAlumno(solicitud),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });

    test('sin conexión produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      await expectLater(
        datasource(client).registrarAlumno(solicitud),
        throwsA(isA<NetworkException>()),
      );
    });

    test('URL http remota se rechaza con ConfigException', () {
      final client = MockClient((_) async => http.Response('{}', 201));

      expect(
        () => HttpAlumnosDataSource(
          baseUrl: 'http://api.ejemplo.com/api/v1',
          tokenProvider: () async => 'jwt-admin',
          client: client,
        ),
        throwsA(isA<ConfigException>()),
      );
    });
  });

  group('HttpAlumnosDataSource.listarAlumnos', () {
    test('200: envía rol=ALUMNO y mapea la lista', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/usuarios');
        expect(request.url.queryParameters['rol'], 'ALUMNO');
        expect(request.url.queryParameters.containsKey('q'), isFalse);
        expect(request.url.queryParameters.containsKey('activo'), isFalse);
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return http.Response(jsonEncode([cuerpoAlumno()]), 200);
      });

      final modelos = await datasource(client).listarAlumnos();

      expect(modelos, hasLength(1));
      expect(modelos.single.id, 42);
      expect(modelos.single.rol, 'ALUMNO');
    });

    test('200: agrega la búsqueda y el filtro de estado', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['rol'], 'ALUMNO');
        expect(request.url.queryParameters['q'], 'ana');
        expect(request.url.queryParameters['activo'], 'false');
        return http.Response(jsonEncode([]), 200);
      });

      final modelos = await datasource(client)
          .listarAlumnos(busqueda: '  ana  ', activo: false);

      expect(modelos, isEmpty);
    });

    test('200 con cuerpo que no es lista produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'id': 1}), 200),
      );

      await expectLater(
        datasource(client).listarAlumnos(),
        throwsA(isA<ServerException>()),
      );
    });

    test('401 produce AuthException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 401, 'message': 'Unauthorized'}),
          401,
        ),
      );

      await expectLater(
        datasource(client).listarAlumnos(),
        throwsA(isA<AuthException>()),
      );
    });

    test('sin conexión produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      await expectLater(
        datasource(client).listarAlumnos(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('HttpAlumnosDataSource.cambiarEstado', () {
    test('200: envía solo {activo} al PATCH (baja lógica)', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), '$baseUrl/usuarios/42');
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        expect(jsonDecode(request.body), {'activo': false});
        return http.Response(
          jsonEncode({...cuerpoAlumno(), 'activo': false}),
          200,
        );
      });

      final model = await datasource(client)
          .cambiarEstado(id: 42, activo: false);

      expect(model.id, 42);
      expect(model.activo, isFalse);
      // CA HU-AD-12: la baja es lógica; el registro se conserva.
      expect(model.matricula, '20231234');
      expect(model.fullName, 'Ana López');
    });

    test('200: la reactivación envía {activo: true}', () async {
      final client = MockClient((request) async {
        expect(jsonDecode(request.body), {'activo': true});
        return http.Response(jsonEncode(cuerpoAlumno()), 200);
      });

      final model = await datasource(client)
          .cambiarEstado(id: 42, activo: true);

      expect(model.activo, isTrue);
    });

    test('404 produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 404,
            'message': 'Usuario 42 no encontrado',
          }),
          404,
        ),
      );

      await expectLater(
        datasource(client).cambiarEstado(id: 42, activo: false),
        throwsA(isA<ServerException>()),
      );
    });

    test('401 produce AuthException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 401, 'message': 'Unauthorized'}),
          401,
        ),
      );

      await expectLater(
        datasource(client).cambiarEstado(id: 42, activo: false),
        throwsA(isA<AuthException>()),
      );
    });

    test('sin token no intenta la petición y lanza AuthException', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response('{}', 200);
      });

      await expectLater(
        datasource(
          client,
          tokenProvider: () async => '',
        ).cambiarEstado(id: 42, activo: false),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });
  });
}

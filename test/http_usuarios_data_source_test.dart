import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_tecnico.dart';
import 'package:scei_qr/dominio/edicion_tecnico.dart';
import 'package:scei_qr/features/usuarios/data/datasources/http_usuarios_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3000/api/v1';

  final solicitud = const SolicitudAltaTecnico(
    nombreCompleto: 'Carlos Mena',
    correo: 'Carlos.Mena@UTEZ.EDU.MX',
    usuario: 'cmena',
    contrasenaInicial: 'Password123!',
  );

  Map<String, dynamic> cuerpoTecnico() => {
    'id': 7,
    'username': 'cmena',
    'fullName': 'Carlos Mena',
    'correo': 'carlos.mena@utez.edu.mx',
    'matricula': null,
    'rol': 'SOPORTE',
    'activo': true,
    'createdAt': '2026-11-05T12:00:00.000Z',
  };

  HttpUsuariosDataSource datasource(
    http.Client client, {
    TokenProvider? tokenProvider,
  }) {
    return HttpUsuariosDataSource(
      baseUrl: baseUrl,
      tokenProvider: tokenProvider ?? () async => 'jwt-admin',
      client: client,
    );
  }

  group('HttpUsuariosDataSource.registrarTecnico', () {
    test('201: envía el alta con token y rol SOPORTE', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), '$baseUrl/usuarios');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        expect(jsonDecode(request.body), {
          'username': 'cmena',
          'password': 'Password123!',
          'fullName': 'Carlos Mena',
          'correo': 'carlos.mena@utez.edu.mx',
          'rol': 'SOPORTE',
        });
        return http.Response(jsonEncode(cuerpoTecnico()), 201);
      });

      final model = await datasource(client).registrarTecnico(solicitud);

      expect(model.id, 7);
      expect(model.username, 'cmena');
      expect(model.fullName, 'Carlos Mena');
      expect(model.correo, 'carlos.mena@utez.edu.mx');
      expect(model.activo, isTrue);
      expect(model.createdAt, isNotNull);
    });

    test('normaliza la URL base con barras finales', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/usuarios');
        return http.Response(jsonEncode(cuerpoTecnico()), 201);
      });

      final ds = HttpUsuariosDataSource(
        baseUrl: '$baseUrl///',
        tokenProvider: () async => 'jwt-admin',
        client: client,
      );

      await ds.registrarTecnico(solicitud);
    });

    test('409 de correo produce ConflictException con campo correo', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 409,
            'message': 'El correo "carlos.mena@utez.edu.mx" ya existe',
            'error': 'Conflict',
          }),
          409,
        ),
      );

      await expectLater(
        datasource(client).registrarTecnico(solicitud),
        throwsA(
          isA<ConflictException>()
              .having((e) => e.campo, 'campo', 'correo')
              .having(
                (e) => e.message,
                'mensaje',
                'El correo "carlos.mena@utez.edu.mx" ya existe',
              ),
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
              'message': 'El usuario "cmena" ya existe',
              'error': 'Conflict',
            }),
            409,
          ),
        );

        await expectLater(
          datasource(client).registrarTecnico(solicitud),
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
            'message': ['correo: formato inválido', 'password: muy corta'],
            'error': 'Bad Request',
          }),
          400,
        ),
      );

      await expectLater(
        datasource(client).registrarTecnico(solicitud),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'mensaje',
            'correo: formato inválido password: muy corta',
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
        datasource(client).registrarTecnico(solicitud),
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
        datasource(client).registrarTecnico(solicitud),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('500 produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response('{"statusCode":500}', 500),
      );

      await expectLater(
        datasource(client).registrarTecnico(solicitud),
        throwsA(isA<ServerException>()),
      );
    });

    test('201 con cuerpo inválido produce ServerException', () async {
      final client = MockClient((_) async => http.Response('<html>', 201));

      await expectLater(
        datasource(client).registrarTecnico(solicitud),
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
        ).registrarTecnico(solicitud),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });

    test('sin conexión produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      await expectLater(
        datasource(client).registrarTecnico(solicitud),
        throwsA(isA<NetworkException>()),
      );
    });

    test('URL http remota se rechaza con ConfigException', () {
      final client = MockClient((_) async => http.Response('{}', 201));

      expect(
        () => HttpUsuariosDataSource(
          baseUrl: 'http://api.ejemplo.com/api/v1',
          tokenProvider: () async => 'jwt-admin',
          client: client,
        ),
        throwsA(isA<ConfigException>()),
      );
    });
  });

  group('HttpUsuariosDataSource.listarTecnicos', () {
    test('envía GET con rol SOPORTE, búsqueda y token', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/usuarios');
        expect(request.url.queryParameters, {'rol': 'SOPORTE', 'q': 'Carlos'});
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return http.Response(
          jsonEncode([
            cuerpoTecnico(),
            {
              ...cuerpoTecnico(),
              'id': 8,
              'username': 'lopez',
              'fullName': 'Lucía López',
              'correo': 'lucia@utez.edu.mx',
              'activo': false,
            },
          ]),
          200,
        );
      });

      final tecnicos = await datasource(client)
          .listarTecnicos(busqueda: '  Carlos  ');

      expect(tecnicos, hasLength(2));
      expect(tecnicos.first.username, 'cmena');
      expect(tecnicos.last.fullName, 'Lucía López');
      expect(tecnicos.last.activo, isFalse);
    });

    test('omite q cuando la búsqueda está vacía', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters, {'rol': 'SOPORTE'});
        return http.Response(jsonEncode([cuerpoTecnico()]), 200);
      });

      final tecnicos = await datasource(client).listarTecnicos(busqueda: '   ');

      expect(tecnicos, hasLength(1));
    });

    test('envía activo=true al filtrar activos', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters, {
          'rol': 'SOPORTE',
          'activo': 'true',
        });
        return http.Response(jsonEncode([cuerpoTecnico()]), 200);
      });

      final tecnicos = await datasource(client).listarTecnicos(activo: true);

      expect(tecnicos, hasLength(1));
    });

    test('envía activo=false al filtrar inactivos', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters, {
          'rol': 'SOPORTE',
          'q': 'Carlos',
          'activo': 'false',
        });
        return http.Response(
          jsonEncode([
            {...cuerpoTecnico(), 'activo': false},
          ]),
          200,
        );
      });

      final tecnicos = await datasource(client)
          .listarTecnicos(busqueda: 'Carlos', activo: false);

      expect(tecnicos.single.activo, isFalse);
    });

    test('cuerpo que no es lista produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'items': []}), 200),
      );

      await expectLater(
        datasource(client).listarTecnicos(),
        throwsA(isA<ServerException>()),
      );
    });

    test('401 produce AuthException', () async {
      final client = MockClient(
        (_) async => http.Response('{"message":"Unauthorized"}', 401),
      );

      await expectLater(
        datasource(client).listarTecnicos(),
        throwsA(isA<AuthException>()),
      );
    });

    test('sin token no intenta la petición y lanza AuthException', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response('[]', 200);
      });

      await expectLater(
        datasource(client, tokenProvider: () async => null).listarTecnicos(),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });
  });

  group('HttpUsuariosDataSource.editarTecnico', () {
    const edicion = SolicitudEdicionTecnico(
      nombreCompleto: 'Carlos Mena',
      correo: 'Carlos.Mena@UTEZ.EDU.MX',
      contrasenaNueva: 'NuevaPassword123!',
    );

    test('envía PATCH con datos de contacto y contraseña nueva', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), '$baseUrl/usuarios/7');
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        expect(jsonDecode(request.body), {
          'fullName': 'Carlos Mena',
          'correo': 'carlos.mena@utez.edu.mx',
          'password': 'NuevaPassword123!',
        });
        return http.Response(jsonEncode(cuerpoTecnico()), 200);
      });

      final tecnico = await datasource(client).editarTecnico(7, edicion);

      expect(tecnico.id, 7);
      expect(tecnico.username, 'cmena');
    });

    test('no envía password si no se capturó una nueva', () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('password'), isFalse);
        return http.Response(jsonEncode(cuerpoTecnico()), 200);
      });

      await datasource(client).editarTecnico(
        7,
        const SolicitudEdicionTecnico(
          nombreCompleto: 'Carlos Mena',
          correo: 'carlos.mena@utez.edu.mx',
        ),
      );
    });

    test('409 produce ConflictException con el campo del conflicto', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 409,
            'message': 'El correo "carlos.mena@utez.edu.mx" ya existe',
          }),
          409,
        ),
      );

      await expectLater(
        datasource(client).editarTecnico(7, edicion),
        throwsA(
          isA<ConflictException>().having((e) => e.campo, 'campo', 'correo'),
        ),
      );
    });

    test(
      '404 produce ServerException con mensaje de técnico inexistente',
      () async {
        final client = MockClient(
          (_) async => http.Response('{"message":"Not found"}', 404),
        );

        await expectLater(
          datasource(client).editarTecnico(7, edicion),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'mensaje',
              'El técnico ya no existe.',
            ),
          ),
        );
      },
    );

    test('400 produce ValidationException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': ['correo: formato inválido'],
          }),
          400,
        ),
      );

      await expectLater(
        datasource(client).editarTecnico(7, edicion),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('HttpUsuariosDataSource.cambiarEstadoTecnico', () {
    test('envía PATCH con el nuevo estado', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), '$baseUrl/usuarios/7');
        expect(jsonDecode(request.body), {'activo': false});
        return http.Response(
          jsonEncode({...cuerpoTecnico(), 'activo': false}),
          200,
        );
      });

      final tecnico = await datasource(client)
          .cambiarEstadoTecnico(7, activo: false);

      expect(tecnico.activo, isFalse);
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/features/equipos/data/datasources/http_equipos_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3000/api/v1';

  const solicitud = SolicitudAltaEquipo(
    identificador: 'LAB-PC-001',
    laboratorio: 'Laboratorio de Cómputo 1',
    ubicacion: 'Fila A, Mesa 3',
    descripcion: 'Dell OptiPlex 3080',
  );

  Map<String, dynamic> cuerpoEquipo({bool activo = true}) => {
    'id': 12,
    'codigo': 'LAB-PC-001',
    'nombre': 'LAB-PC-001',
    'descripcion': 'Dell OptiPlex 3080',
    'ubicacion': 'Fila A, Mesa 3',
    'qrToken': 'qr-token',
    'activo': activo,
    'createdAt': '2026-11-05T12:00:00.000Z',
  };

  HttpEquiposDataSource datasource(
    http.Client client, {
    TokenProvider? tokenProvider,
  }) {
    return HttpEquiposDataSource(
      baseUrl: baseUrl,
      tokenProvider: tokenProvider ?? () async => 'jwt-admin',
      client: client,
    );
  }

  group('toCreateEquipoPayload (HU-AD-04)', () {
    test('mapea identificador→codigo, descripción y ubicación sin', () {
      expect(toCreateEquipoPayload(solicitud), {
        'codigo': 'LAB-PC-001',
        // TODO-TEMP: `nombre` no existe en la HU; provisorio = identificador.
        'nombre': 'LAB-PC-001',
        'descripcion': 'Dell OptiPlex 3080',
        'ubicacion': 'Fila A, Mesa 3',
      });
    });

    test(
      'NO envía laboratorio (extra="forbid") ni activo (lo asigna el servidor)',
      () {
        final payload = toCreateEquipoPayload(solicitud);

        expect(payload.containsKey('laboratorio'), isFalse);
        expect(payload.containsKey('activo'), isFalse);
      },
    );

    test('envía descripcion null cuando está vacía', () {
      final payload = toCreateEquipoPayload(
        const SolicitudAltaEquipo(
          identificador: 'LAB-PC-001',
          laboratorio: 'Laboratorio de Cómputo 1',
          ubicacion: 'Fila A',
        ),
      );

      expect(payload['descripcion'], isNull);
    });

    test('recorta espacios sobrantes antes de enviar', () {
      final payload = toCreateEquipoPayload(
        const SolicitudAltaEquipo(
          identificador: '  LAB-PC-001  ',
          laboratorio: ' Laboratorio ',
          ubicacion: '  Fila A  ',
          descripcion: '  Dell  ',
        ),
      );

      expect(payload['codigo'], 'LAB-PC-001');
      expect(payload['ubicacion'], 'Fila A');
      expect(payload['descripcion'], 'Dell');
    });
  });

  group('HttpEquiposDataSource.registrarEquipo', () {
    test(
      '201: envía el alta a /equipos con token y devuelve estado Activo',
      () async {
        final client = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), '$baseUrl/equipos');
          expect(request.headers['Content-Type'], contains('application/json'));
          expect(request.headers['Authorization'], 'Bearer jwt-admin');
          expect(jsonDecode(request.body), {
            'codigo': 'LAB-PC-001',
            'nombre': 'LAB-PC-001',
            'descripcion': 'Dell OptiPlex 3080',
            'ubicacion': 'Fila A, Mesa 3',
          });
          return http.Response(jsonEncode(cuerpoEquipo()), 201);
        });

        final model = await datasource(client).registrarEquipo(solicitud);

        expect(model.id, 12);
        expect(model.identificador, 'LAB-PC-001');
        expect(model.ubicacion, 'Fila A, Mesa 3');
        expect(model.descripcion, 'Dell OptiPlex 3080');
        expect(model.activo, isTrue);
        expect(model.fechaAlta, isNotNull);
      },
    );

    test('201 con estado distinto de Activo produce ServerException '
        '(verificación del CA)', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode(cuerpoEquipo(activo: false)), 201),
      );

      await expectLater(
        datasource(client).registrarEquipo(solicitud),
        throwsA(isA<ServerException>()),
      );
    });

    test('normaliza la URL base con barras finales', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/equipos');
        return http.Response(jsonEncode(cuerpoEquipo()), 201);
      });

      final ds = HttpEquiposDataSource(
        baseUrl: '$baseUrl///',
        tokenProvider: () async => 'jwt-admin',
        client: client,
      );

      await ds.registrarEquipo(solicitud);
    });

    test(
      '409 de unicidad produce ConflictException con campo identificador',
      () async {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'statusCode': 409,
              'message': 'El código "LAB-PC-001" ya está registrado',
              'error': 'Conflict',
            }),
            409,
          ),
        );

        await expectLater(
          datasource(client).registrarEquipo(solicitud),
          throwsA(
            isA<ConflictException>()
                .having((e) => e.campo, 'campo', 'identificador')
                .having(
                  (e) => e.message,
                  'mensaje',
                  'El código "LAB-PC-001" ya está registrado',
                ),
          ),
        );
      },
    );

    test('400 convierte la lista de mensajes en ValidationException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'statusCode': 400,
            'message': ['ubicacion: Field required'],
            'error': 'Bad Request',
          }),
          400,
        ),
      );

      await expectLater(
        datasource(client).registrarEquipo(solicitud),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'mensaje',
            'ubicacion: Field required',
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
        datasource(client).registrarEquipo(solicitud),
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
        datasource(client).registrarEquipo(solicitud),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('500 produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response('{"statusCode":500}', 500),
      );

      await expectLater(
        datasource(client).registrarEquipo(solicitud),
        throwsA(isA<ServerException>()),
      );
    });

    test('201 con cuerpo inválido produce ServerException', () async {
      final client = MockClient((_) async => http.Response('<html>', 201));

      await expectLater(
        datasource(client).registrarEquipo(solicitud),
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
        ).registrarEquipo(solicitud),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });

    test('sin conexión produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      await expectLater(
        datasource(client).registrarEquipo(solicitud),
        throwsA(isA<NetworkException>()),
      );
    });

    test('URL http remota se rechaza con ConfigException', () {
      final client = MockClient((_) async => http.Response('{}', 201));

      expect(
        () => HttpEquiposDataSource(
          baseUrl: 'http://api.ejemplo.com/api/v1',
          tokenProvider: () async => 'jwt-admin',
          client: client,
        ),
        throwsA(isA<ConfigException>()),
      );
    });
  });
}

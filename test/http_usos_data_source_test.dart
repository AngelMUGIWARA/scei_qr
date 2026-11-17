import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/features/usos/data/datasources/http_usos_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api/v1';

  Map<String, dynamic> cuerpoUso() => {
    'id': 5,
    'alumnoId': 9,
    'equipoId': 12,
    'inicio': '2026-11-08T15:30:00.000Z',
    'fin': null,
    'estado': 'ACTIVO',
    'equipo': {
      'id': 12,
      'codigo': 'LAB-PC-001',
      'nombre': 'LAB-PC-001',
      'descripcion': 'Dell OptiPlex',
      'ubicacion': 'Fila A, Mesa 3',
      'qrToken': 'qr-token',
      'activo': true,
      'createdAt': '2026-11-05T12:00:00.000Z',
    },
  };

  HttpUsosDataSource datasource(http.Client client) {
    return HttpUsosDataSource(
      baseUrl: baseUrl,
      tokenProvider: () async => 'jwt-alumno',
      client: client,
    );
  }

  group('HttpUsosDataSource.iniciarUso — HU-AL-03', () {
    test('POST /usos envía el qrToken y devuelve el uso creado', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), '$baseUrl/usos');
        expect(request.headers['Authorization'], 'Bearer jwt-alumno');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(jsonDecode(request.body), {'qrToken': 'qr-token'});
        return http.Response(jsonEncode(cuerpoUso()), 201);
      });

      final model = await datasource(client).iniciarUso('qr-token');

      expect(model.id, 5);
      expect(model.alumnoId, 9);
      expect(model.equipoId, 12);
      expect(model.estado.name, 'activo');
    });

    test('recorta espacios del token escaneado', () async {
      final client = MockClient((request) async {
        expect(jsonDecode(request.body), {'qrToken': 'qr-token'});
        return http.Response(jsonEncode(cuerpoUso()), 201);
      });

      await datasource(client).iniciarUso('  qr-token  ');
    });

    test('token vacío lanza ValidationException sin llamar a la red', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response(jsonEncode(cuerpoUso()), 201);
      });

      await expectLater(
        datasource(client).iniciarUso('   '),
        throwsA(isA<ValidationException>()),
      );
      expect(llamadas, 0);
    });

    test('sin token de sesión no intenta la petición', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response(jsonEncode(cuerpoUso()), 201);
      });
      final ds = HttpUsosDataSource(
        baseUrl: baseUrl,
        tokenProvider: () async => null,
        client: client,
      );

      await expectLater(
        ds.iniciarUso('qr-token'),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });

    test('409 produce ConflictException con el mensaje del backend', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'El equipo ya está en uso. Finaliza el uso actual.',
          }),
          409,
        ),
      );

      await expectLater(
        datasource(client).iniciarUso('qr-token'),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'El equipo ya está en uso. Finaliza el uso actual.',
          ),
        ),
      );
    });

    test('404 produce NotFoundException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'QR no válido o equipo inactivo'}),
          404,
        ),
      );

      await expectLater(
        datasource(client).iniciarUso('qr-token'),
        throwsA(isA<NotFoundException>()),
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
        datasource(client).iniciarUso('qr-token'),
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
        datasource(client).iniciarUso('qr-token'),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('422 produce ValidationException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': ['qrToken no debe estar vacío'],
          }),
          422,
        ),
      );

      await expectLater(
        datasource(client).iniciarUso('qr-token'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'qrToken no debe estar vacío',
          ),
        ),
      );
    });

    test('500 produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response('{"statusCode":500}', 500),
      );

      await expectLater(
        datasource(client).iniciarUso('qr-token'),
        throwsA(isA<ServerException>()),
      );
    });

    test('respuesta 201 con cuerpo inválido produce ServerException', () async {
      final client = MockClient((_) async => http.Response('<html>', 201));

      await expectLater(
        datasource(client).iniciarUso('qr-token'),
        throwsA(isA<ServerException>()),
      );
    });

    test('sin conexión produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      await expectLater(
        datasource(client).iniciarUso('qr-token'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}

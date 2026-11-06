import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/features/equipos/data/datasources/http_equipos_data_source.dart';
import 'package:scei_qr/features/equipos/data/models/equipo_model.dart';

void main() {
  const baseUrl = 'http://localhost:3000/api/v1';

  /// PNG de 1x1 válido (los bytes deben decodificarse en Image.memory).
  final pngBytes = base64.decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
    'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  Map<String, dynamic> cuerpoEquipo({String qrToken = 'qr-token-nuevo'}) => {
    'id': 12,
    'codigo': 'LAB-PC-001',
    'nombre': 'LAB-PC-001',
    'descripcion': 'Dell OptiPlex 3080',
    'ubicacion': 'Fila A, Mesa 3',
    'qrToken': qrToken,
    'activo': true,
    'createdAt': '2026-11-05T12:00:00.000Z',
  };

  HttpEquiposDataSource datasource(http.Client client) {
    return HttpEquiposDataSource(
      baseUrl: baseUrl,
      tokenProvider: () async => 'jwt-admin',
      client: client,
    );
  }

  group('EquipoModel — HU-AD-06 (qrToken)', () {
    test('mapea qrToken al dominio', () {
      final model = EquipoModel.fromJson(cuerpoEquipo());

      expect(model.qrToken, 'qr-token-nuevo');
      expect(model.toEntity().qrToken, 'qr-token-nuevo');
    });

    test('tolera respuestas sin qrToken (lo deja nulo)', () {
      final json = cuerpoEquipo()..remove('qrToken');

      expect(EquipoModel.fromJson(json).qrToken, isNull);
    });
  });

  group('HttpEquiposDataSource.regenerarQr', () {
    test('POST /equipos/{id}/regenerar-qr devuelve el token nuevo', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          '$baseUrl/equipos/12/regenerar-qr',
        );
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        // CA: la regeneración no envía datos; el token lo decide el servidor.
        expect(request.body, isEmpty);
        return http.Response(
          jsonEncode(cuerpoEquipo(qrToken: 'qr-token-v2')),
          201,
        );
      });

      final model = await datasource(client).regenerarQr(12);

      expect(model.qrToken, 'qr-token-v2');
      expect(model.identificador, 'LAB-PC-001');
    });

    test('401 produce AuthException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 401, 'message': 'Unauthorized'}),
          401,
        ),
      );

      await expectLater(
        datasource(client).regenerarQr(12),
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
        datasource(client).regenerarQr(12),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('404 produce NotFoundException', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'message': 'Equipo no encontrado'}), 404),
      );

      await expectLater(
        datasource(client).regenerarQr(99),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('201 con cuerpo inválido produce ServerException', () async {
      final client = MockClient((_) async => http.Response('<html>', 201));

      await expectLater(
        datasource(client).regenerarQr(12),
        throwsA(isA<ServerException>()),
      );
    });

    test('sin token no intenta la petición', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response('{}', 201);
      });

      final ds = HttpEquiposDataSource(
        baseUrl: baseUrl,
        tokenProvider: () async => null,
        client: client,
      );

      await expectLater(
        ds.regenerarQr(12),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });
  });

  group('HttpEquiposDataSource.obtenerImagenQr', () {
    test('GET /equipos/{id}/qr devuelve los bytes del PNG', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$baseUrl/equipos/12/qr');
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return http.Response.bytes(
          pngBytes,
          200,
          headers: {'content-type': 'image/png'},
        );
      });

      final bytes = await datasource(client).obtenerImagenQr(12);

      expect(bytes, isA<Uint8List>());
      expect(bytes, pngBytes);
    });

    test('401 produce AuthException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 401, 'message': 'Unauthorized'}),
          401,
        ),
      );

      await expectLater(
        datasource(client).obtenerImagenQr(12),
        throwsA(isA<AuthException>()),
      );
    });

    test('404 produce NotFoundException', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'message': 'Equipo no encontrado'}), 404),
      );

      await expectLater(
        datasource(client).obtenerImagenQr(99),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('500 produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response('{"statusCode":500}', 500),
      );

      await expectLater(
        datasource(client).obtenerImagenQr(12),
        throwsA(isA<ServerException>()),
      );
    });

    test('respuesta 200 sin bytes produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response.bytes(
          Uint8List(0),
          200,
          headers: {'content-type': 'image/png'},
        ),
      );

      await expectLater(
        datasource(client).obtenerImagenQr(12),
        throwsA(isA<ServerException>()),
      );
    });

    test('sin conexión produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      await expectLater(
        datasource(client).obtenerImagenQr(12),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}

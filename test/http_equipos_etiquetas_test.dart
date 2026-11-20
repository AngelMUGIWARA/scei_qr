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

  final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.7\netiqueta'));

  HttpEquiposDataSource datasource(http.Client client) {
    return HttpEquiposDataSource(
      baseUrl: baseUrl,
      tokenProvider: () async => 'jwt-admin',
      client: client,
    );
  }

  group('EquipoModel — laboratorio (HU-AD-07)', () {
    test('mapea laboratorio cuando viene en la respuesta', () {
      final model = EquipoModel.fromJson({
        'id': 12,
        'codigo': 'LAB-PC-001',
        'nombre': 'PC de laboratorio',
        'descripcion': null,
        'ubicacion': 'Fila A',
        'laboratorio': 'Laboratorio de Cómputo 1',
        'qrToken': 'qr-token',
        'activo': true,
        'createdAt': '2026-11-05T12:00:00.000Z',
      });

      expect(model.laboratorio, 'Laboratorio de Cómputo 1');
      expect(model.toEntity().laboratorio, 'Laboratorio de Cómputo 1');
    });

    test('tolera respuestas sin laboratorio', () {
      final model = EquipoModel.fromJson({
        'id': 12,
        'codigo': 'LAB-PC-001',
        'nombre': 'PC',
        'descripcion': null,
        'ubicacion': 'Fila A',
        'qrToken': 'qr-token',
        'activo': true,
        'createdAt': '2026-11-05T12:00:00.000Z',
      });

      expect(model.laboratorio, isNull);
    });
  });

  group('HttpEquiposDataSource.descargarEtiquetaQrPdf', () {
    test('GET /equipos/{id}/qr?format=pdf devuelve el PDF', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$baseUrl/equipos/12/qr?format=pdf');
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return http.Response.bytes(
          pdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final bytes = await datasource(client).descargarEtiquetaQrPdf(12);

      expect(bytes, pdfBytes);
    });

    test('403 produce ForbiddenException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'statusCode': 403, 'message': 'Forbidden'}),
          403,
        ),
      );

      await expectLater(
        datasource(client).descargarEtiquetaQrPdf(12),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('respuesta 200 que no es PDF produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response.bytes(
          Uint8List.fromList(utf8.encode('<html>no pdf</html>')),
          200,
          headers: {'content-type': 'text/html'},
        ),
      );

      await expectLater(
        datasource(client).descargarEtiquetaQrPdf(12),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('HttpEquiposDataSource.descargarEtiquetasLote', () {
    test('GET /equipos/etiquetas envía los filtros del lote', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/equipos/etiquetas');
        expect(request.url.queryParameters, {
          'laboratorio': 'Laboratorio de Cómputo 1',
          'ubicacion': 'Fila A',
          'activo': 'true',
        });
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return http.Response.bytes(
          pdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final bytes = await datasource(client).descargarEtiquetasLote(
        laboratorio: ' Laboratorio de Cómputo 1 ',
        ubicacion: ' Fila A ',
        activo: true,
      );

      expect(bytes, pdfBytes);
    });

    test('404 produce NotFoundException con el mensaje del backend', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'No hay equipos que coincidan con el lote solicitado',
          }),
          404,
        ),
      );

      await expectLater(
        datasource(client).descargarEtiquetasLote(laboratorio: 'Nadie'),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'No hay equipos que coincidan con el lote solicitado',
          ),
        ),
      );
    });

    test('sin token no intenta la petición', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response.bytes(pdfBytes, 200);
      });
      final ds = HttpEquiposDataSource(
        baseUrl: baseUrl,
        tokenProvider: () async => null,
        client: client,
      );

      await expectLater(
        ds.descargarEtiquetasLote(laboratorio: 'Lab'),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });
  });
}

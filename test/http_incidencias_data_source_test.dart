import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/incidencia.dart';
import 'package:scei_qr/features/incidencias/data/datasources/http_incidencias_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api/v1';

  /// Respuesta real de `POST /incidencias` (serializador `incident_public`).
  Map<String, dynamic> cuerpoIncident({int id = 42}) => {
    'id': id,
    'equipoId': 12,
    'reportadaPorId': 9,
    'atendidaPorId': null,
    'titulo': 'Hardware',
    'descripcion': 'La pantalla parpadea',
    'fotoUrl': null,
    'estado': 'PENDIENTE',
    'solucion': null,
    'creadaEn': '2026-11-25T10:30:00.000Z',
    'actualizadaEn': '2026-11-25T10:30:00.000Z',
    'equipo': {'codigo': 'LAB-PC-001', 'ubicacion': 'Laboratorio 1'},
    'reportadaPor': {
      'id': 9,
      'username': 'alumno1',
      'fullName': 'Lucía Fernández',
    },
    'atendidaPor': null,
  };

  HttpIncidenciasDataSource datasource(http.Client client) =>
      HttpIncidenciasDataSource(
        baseUrl: baseUrl,
        tokenProvider: () async => 'jwt-alumno',
        client: client,
      );

  /// Cliente que responde con [status] y [body].
  MockClient respondiendo(int status, {Object? body}) => MockClient(
    (_) async => http.Response(
      jsonEncode(body ?? cuerpoIncident()),
      status,
      headers: {'content-type': 'application/json'},
    ),
  );

  group('HttpIncidenciasDataSource.reportarIncidencia — HU-AL-06', () {
    test(
      'POST multipart con Bearer, los 3 campos y el modelo devuelto',
      () async {
        late http.Request capturada;
        final client = MockClient((request) async {
          capturada = request;
          return http.Response(
            jsonEncode(cuerpoIncident()),
            201,
            headers: {'content-type': 'application/json'},
          );
        });

        final model = await datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: '  La pantalla parpadea  ',
        );

        // Petición.
        expect(capturada.method, 'POST');
        expect(capturada.url.toString(), '$baseUrl/incidencias');
        expect(capturada.headers['Authorization'], 'Bearer jwt-alumno');
        expect(
          capturada.headers['Content-Type'],
          startsWith('multipart/form-data'),
        );
        expect(capturada.headers['Content-Type'], contains('boundary='));

        // Campos del formulario (FastAPI espera Form/File).
        final cuerpo = utf8.decode(capturada.bodyBytes);
        expect(cuerpo, contains('name="equipoId"'));
        expect(cuerpo, contains('name="titulo"'));
        expect(cuerpo, contains('name="descripcion"'));
        expect(cuerpo, contains('Hardware')); // el tipo viaja como titulo
        expect(cuerpo, contains('La pantalla parpadea'));
        // La descripción se recorta antes de enviarse.
        expect(cuerpo.contains('La pantalla parpadea  '), isFalse);

        // Modelo.
        expect(model.id, 42);
        expect(model.folio, 'INC-000042');
        expect(model.equipoId, 12);
        expect(model.alumnoId, 9);
        expect(model.tipo, TipoProblema.hardware);
        expect(model.estado, EstadoIncidencia.pendiente);
        expect(model.equipoIdentificador, 'LAB-PC-001');
        expect(model.fechaReporte.isUtc, isTrue);
      },
    );

    test('sin token de sesión no intenta la petición', () async {
      var llamadas = 0;
      final client = MockClient((_) async {
        llamadas++;
        return http.Response(jsonEncode(cuerpoIncident()), 201);
      });
      final ds = HttpIncidenciasDataSource(
        baseUrl: baseUrl,
        tokenProvider: () async => null,
        client: client,
      );

      await expectLater(
        ds.reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(llamadas, 0);
    });

    test(
      '400 produce ValidationException con el mensaje del backend',
      () async {
        final client = respondiendo(
          400,
          body: {'message': 'El equipo no está activo'},
        );

        await expectLater(
          datasource(client).reportarIncidencia(
            equipoId: 12,
            tipo: TipoProblema.hardware,
            descripcion: 'falla',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'mensaje',
              'El equipo no está activo',
            ),
          ),
        );
      },
    );

    test('401 produce AuthException', () async {
      final client = respondiendo(401, body: {'message': 'Token expirado'});

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('403 produce ForbiddenException', () async {
      final client = respondiendo(403, body: {'message': 'Rol no válido'});

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('404 produce NotFoundException con el mensaje del backend', () async {
      final client = respondiendo(404, body: {'message': 'Equipo inexistente'});

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 999,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'mensaje',
            'Equipo inexistente',
          ),
        ),
      );
    });

    test('404 sin mensaje usa el mensaje por defecto', () async {
      final client = respondiendo(404, body: {});

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'mensaje',
            'El equipo no existe o está dado de baja.',
          ),
        ),
      );
    });

    test(
      '409 (fuera del contrato del API) se trata como error de servidor',
      () async {
        final client = respondiendo(409, body: {'message': 'Duplicado'});

        await expectLater(
          datasource(client).reportarIncidencia(
            equipoId: 12,
            tipo: TipoProblema.hardware,
            descripcion: 'falla',
          ),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'mensaje',
              const ServerException().message,
            ),
          ),
        );
      },
    );

    test(
      '422 produce ValidationException con el mensaje del backend',
      () async {
        final client = respondiendo(
          422,
          body: {'message': 'La descripción es demasiado corta'},
        );

        await expectLater(
          datasource(client).reportarIncidencia(
            equipoId: 12,
            tipo: TipoProblema.hardware,
            descripcion: 'x',
          ),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test(
      '422 con la lista de errores de FastAPI los une en un mensaje',
      () async {
        final client = respondiendo(
          422,
          body: {
            'message': ['Field required', 'String too short'],
          },
        );

        await expectLater(
          datasource(client).reportarIncidencia(
            equipoId: 12,
            tipo: TipoProblema.hardware,
            descripcion: '',
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'mensaje',
              'Field required String too short',
            ),
          ),
        );
      },
    );

    test('500 produce ServerException', () async {
      final client = respondiendo(500, body: {'detail': 'boom'});

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('sin conexión (ClientException) produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Connection refused'),
      );

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('timeout produce NetworkException', () async {
      final client = MockClient(
        (_) async => throw TimeoutException('Se agotó el tiempo'),
      );

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('respuesta 2xx con JSON inválido produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response('<html>error</html>', 200),
      );

      await expectLater(
        datasource(client).reportarIncidencia(
          equipoId: 12,
          tipo: TipoProblema.hardware,
          descripcion: 'falla',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'respuesta 2xx sin los campos obligatorios produce ServerException',
      () async {
        final client = respondiendo(201, body: {'id': 42});

        await expectLater(
          datasource(client).reportarIncidencia(
            equipoId: 12,
            tipo: TipoProblema.hardware,
            descripcion: 'falla',
          ),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}

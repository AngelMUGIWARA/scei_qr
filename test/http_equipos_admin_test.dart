import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/features/equipos/data/datasources/http_equipos_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3000/api/v1';

  Map<String, dynamic> cuerpoEquipo({
    int id = 12,
    String codigo = 'LAB-PC-001',
    bool activo = true,
    String? nombre,
    String? ubicacion,
  }) => {
    'id': id,
    'codigo': codigo,
    'nombre': nombre ?? codigo,
    'descripcion': 'Dell OptiPlex 3080',
    'ubicacion': ubicacion ?? 'Fila A, Mesa 3',
    'qrToken': 'qr-token',
    'activo': activo,
    'createdAt': '2026-11-05T12:00:00.000Z',
  };

  HttpEquiposDataSource datasource(http.Client client) {
    return HttpEquiposDataSource(
      baseUrl: baseUrl,
      tokenProvider: () async => 'jwt-admin',
      client: client,
    );
  }

  group('toUpdateEquipoPayload (HU-AD-05)', () {
    test('envía solo los campos editables y deriva el nombre del código', () {
      const solicitud = SolicitudEdicionEquipo(
        codigo: ' LAB-PC-001 ',
        ubicacion: ' Fila A ',
      );

      expect(toUpdateEquipoPayload(solicitud), {
        'codigo': 'LAB-PC-001',
        'nombre': 'LAB-PC-001',
        'descripcion': null,
        'ubicacion': 'Fila A',
      });
    });

    test('no envía laboratorio, activo ni timestamps', () {
      final payload = toUpdateEquipoPayload(
        const SolicitudEdicionEquipo(
          codigo: 'LAB-PC-001',
          nombre: 'Equipo',
          descripcion: 'Dell',
          ubicacion: 'Fila A',
        ),
      );

      expect(payload.containsKey('laboratorio'), isFalse);
      expect(payload.containsKey('activo'), isFalse);
      expect(payload.containsKey('updated_at'), isFalse);
    });
  });

  group('HttpEquiposDataSource.listarEquipos', () {
    test('envía q, ubicacion y activo y parsea la lista', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/equipos');
        expect(request.url.queryParameters, {
          'q': 'PC',
          'ubicacion': 'Fila A',
          'activo': 'false',
        });
        expect(request.headers['Authorization'], 'Bearer jwt-admin');
        return http.Response(
          jsonEncode([
            cuerpoEquipo(id: 1, codigo: 'PC-1', activo: false),
            cuerpoEquipo(id: 2, codigo: 'PC-2', activo: false),
          ]),
          200,
        );
      });

      final equipos = await datasource(client)
          .listarEquipos(q: ' PC ', ubicacion: ' Fila A ', activo: false);

      expect(equipos, hasLength(2));
      expect(equipos.first.identificador, 'PC-1');
      expect(equipos.last.identificador, 'PC-2');
      expect(equipos.first.activo, isFalse);
    });

    test('omite parámetros vacíos y activo nulo', () async {
      final client = MockClient((request) async {
        expect(request.url.query, isEmpty);
        return http.Response(jsonEncode([cuerpoEquipo()]), 200);
      });

      final equipos = await datasource(client)
          .listarEquipos(q: ' ', ubicacion: '');

      expect(equipos, hasLength(1));
    });

    test('200 con cuerpo inválido produce ServerException', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'no': 'es lista'}), 200),
      );

      await expectLater(
        datasource(client).listarEquipos(),
        throwsA(isA<ServerException>()),
      );
    });

    test('401 produce AuthException', () async {
      final client = MockClient((_) async => http.Response('', 401));

      await expectLater(
        datasource(client).listarEquipos(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('HttpEquiposDataSource.obtenerEquipoPorId', () {
    test('GET /equipos/{id} devuelve el equipo', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$baseUrl/equipos/12');
        return http.Response(jsonEncode(cuerpoEquipo()), 200);
      });

      final equipo = await datasource(client).obtenerEquipoPorId(12);

      expect(equipo.id, 12);
      expect(equipo.identificador, 'LAB-PC-001');
    });

    test('404 produce NotFoundException', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'message': 'Equipo no encontrado'}), 404),
      );

      await expectLater(
        datasource(client).obtenerEquipoPorId(99),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Equipo no encontrado',
          ),
        ),
      );
    });
  });

  group('HttpEquiposDataSource.actualizarEquipo', () {
    test('PATCH /equipos/{id} envía los campos editables', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), '$baseUrl/equipos/12');
        expect(jsonDecode(request.body), {
          'codigo': 'LAB-PC-002',
          'nombre': 'Equipo de diseño',
          'descripcion': 'Dell',
          'ubicacion': 'Fila B',
        });
        return http.Response(
          jsonEncode(cuerpoEquipo(codigo: 'LAB-PC-002', ubicacion: 'Fila B')),
          200,
        );
      });

      final equipo = await datasource(client).actualizarEquipo(
        12,
        const SolicitudEdicionEquipo(
          codigo: 'LAB-PC-002',
          nombre: 'Equipo de diseño',
          descripcion: 'Dell',
          ubicacion: 'Fila B',
        ),
      );

      expect(equipo.identificador, 'LAB-PC-002');
      expect(equipo.ubicacion, 'Fila B');
    });

    test(
      '409 de código produce ConflictException con campo identificador',
      () async {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({'message': 'El código ya está registrado'}),
            409,
          ),
        );

        await expectLater(
          datasource(client).actualizarEquipo(
            12,
            const SolicitudEdicionEquipo(
              codigo: 'LAB-PC-001',
              ubicacion: 'Fila A',
            ),
          ),
          throwsA(
            isA<ConflictException>().having(
              (e) => e.campo,
              'campo',
              'identificador',
            ),
          ),
        );
      },
    );
  });

  group('HttpEquiposDataSource.cambiarEstadoEquipo', () {
    test('PATCH envía únicamente activo=false para dar de baja', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.toString(), '$baseUrl/equipos/12');
        expect(jsonDecode(request.body), {'activo': false});
        return http.Response(jsonEncode(cuerpoEquipo(activo: false)), 200);
      });

      final equipo = await datasource(client)
          .cambiarEstadoEquipo(12, activo: false);

      expect(equipo.activo, isFalse);
    });

    test('PATCH envía activo=true para reactivar', () async {
      final client = MockClient((request) async {
        expect(jsonDecode(request.body), {'activo': true});
        return http.Response(jsonEncode(cuerpoEquipo()), 200);
      });

      final equipo = await datasource(client)
          .cambiarEstadoEquipo(12, activo: true);

      expect(equipo.activo, isTrue);
    });
  });
}

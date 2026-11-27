import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/features/usos/data/datasources/http_usos_data_source.dart';
import 'package:scei_qr/features/usos/data/repositories/usos_repository_impl.dart';

const _baseUrl = 'http://localhost:3001/api/v1';

Map<String, dynamic> _uso({
  required int id,
  required String estado,
  String? fin,
}) => {
  'id': id,
  'alumnoId': 9,
  'equipoId': 12,
  'inicio': '2026-11-08T15:30:00.000Z',
  'fin': fin,
  'estado': estado,
  'equipo': {
    'id': 12,
    'codigo': 'LAB-PC-001',
    'nombre': 'LAB-PC-001',
    'descripcion': 'Dell OptiPlex',
    'ubicacion': 'Fila A, Mesa 3',
    'laboratorio': 'Laboratorio 1',
    'qrToken': 'qr-token',
    'activo': true,
    'createdAt': '2026-11-05T12:00:00.000Z',
  },
};

UsosRepositoryImpl _repo(MockClient client) => UsosRepositoryImpl(
  HttpUsosDataSource(
    baseUrl: _baseUrl,
    tokenProvider: () async => 'jwt-alumno',
    client: client,
  ),
);

void main() {
  group('UsosRepositoryImpl.obtenerUsoActivo — HU-AL-04', () {
    test('elige el registro con estado ACTIVO', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            _uso(id: 3, estado: 'FINALIZADO', fin: '2026-11-07T10:00:00.000Z'),
            _uso(id: 5, estado: 'ACTIVO'),
          ]),
          200,
        ),
      );

      final uso = await _repo(client).obtenerUsoActivo();

      expect(uso, isNotNull);
      expect(uso!.id, 5);
      expect(uso.estaActivo, isTrue);
      expect(uso.equipo?.identificador, 'LAB-PC-001');
    });

    test('sin registros ACTIVO devuelve null', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            _uso(id: 3, estado: 'FINALIZADO', fin: '2026-11-07T10:00:00.000Z'),
          ]),
          200,
        ),
      );

      expect(await _repo(client).obtenerUsoActivo(), isNull);
    });

    test('sin conexión propaga NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Failed host lookup'),
      );

      await expectLater(
        _repo(client).obtenerUsoActivo(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('UsosRepositoryImpl.finalizarUso — HU-AL-04', () {
    test('200 devuelve la entidad finalizada con su duración', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(
            _uso(id: 5, estado: 'FINALIZADO', fin: '2026-11-08T17:05:00.000Z'),
          ),
          200,
        ),
      );

      final uso = await _repo(client).finalizarUso(5);

      expect(uso.estaActivo, isFalse);
      expect(uso.fin, DateTime.utc(2026, 11, 8, 17, 5));
      expect(uso.duracion, const Duration(hours: 1, minutes: 35));
    });

    test('403 propaga ForbiddenException', () async {
      final client = MockClient((_) async => http.Response('{}', 403));

      await expectLater(
        _repo(client).finalizarUso(5),
        throwsA(isA<ForbiddenException>()),
      );
    });

    test('404 propaga NotFoundException', () async {
      final client = MockClient((_) async => http.Response('{}', 404));

      await expectLater(
        _repo(client).finalizarUso(5),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('409 propaga ConflictException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'El uso ya fue finalizado'}),
          409,
        ),
      );

      await expectLater(
        _repo(client).finalizarUso(5),
        throwsA(isA<ConflictException>()),
      );
    });

    test('sin conexión propaga NetworkException', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Connection refused'),
      );

      await expectLater(
        _repo(client).finalizarUso(5),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}

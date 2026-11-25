import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/validar_qr_usecase.dart';
import 'package:scei_qr/features/escaneo/domain/permiso_camara.dart';
import 'package:scei_qr/features/escaneo/presentation/screens/escanear_qr_screen.dart';
import 'package:scei_qr/features/usos/data/datasources/http_usos_data_source.dart';
import 'package:scei_qr/features/usos/data/repositories/usos_repository_impl.dart';
import 'package:scei_qr/features/usos/domain/usecases/registrar_uso_usecase.dart';
import 'package:scei_qr/features/usos/domain/usecases/sincronizar_usos_pendientes_usecase.dart';

import 'fakes_usos.dart';

const _baseUrl = 'http://localhost:3000/api/v1';

const _equipo = Equipo(
  id: 12,
  identificador: 'LAB-PC-001',
  nombre: 'LAB-PC-001',
  ubicacion: 'Fila A, Mesa 3',
  activo: true,
  qrToken: 'token-valido',
);

Map<String, dynamic> _cuerpoUso() => {
  'id': 5,
  'alumnoId': 9,
  'equipoId': 12,
  'inicio': '2026-11-24T10:30:00.000Z',
  'fin': null,
  'estado': 'ACTIVO',
};

HttpUsosDataSource _http(http.Client client) {
  return HttpUsosDataSource(
    baseUrl: _baseUrl,
    tokenProvider: () async => 'jwt-alumno',
    client: client,
  );
}

class _FakeEquiposRepository implements EquiposRepository {
  final List<String> tokens = [];

  @override
  Future<Equipo> resolverQr(String qrToken) async {
    tokens.add(qrToken);
    return _equipo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakePermisoCamara implements PermisoCamara {
  @override
  Future<bool> estaConcedido() async => true;

  @override
  Future<bool> solicitar() async => true;

  @override
  Future<bool> abrirAjustes() async => true;
}

class _CamaraFake {
  void Function(String valor)? onDetectado;

  Widget construir(BuildContext context, void Function(String) detectado) {
    onDetectado = detectado;
    return const SizedBox(key: Key('camara_fake'));
  }
}

class _Flujo {
  const _Flujo({required this.camara, required this.cola});

  final _CamaraFake camara;
  final FakeColaUsosPendientes cola;
}

Future<_Flujo> _escanear(
  WidgetTester tester, {
  required FetchUsosHandler handler,
}) async {
  final cola = FakeColaUsosPendientes();
  final registrar = RegistrarUsoUseCase(
    UsosRepositoryImpl(_http(MockClient(handler))),
    cola,
  );
  final equipos = _FakeEquiposRepository();
  final camara = _CamaraFake();

  await tester.pumpWidget(
    MaterialApp(
      home: EscanearQrScreen(
        validarQrUseCase: ValidarQrUseCase(equipos),
        registrarUsoUseCase: registrar,
        permisoCamara: _FakePermisoCamara(),
        camaraBuilder: camara.construir,
      ),
    ),
  );
  await tester.pump();
  return _Flujo(camara: camara, cola: cola);
}

typedef FetchUsosHandler = Future<http.Response> Function(http.Request);

void main() {
  group('Integración escaneo → registro — HU-AL-03', () {
    testWidgets('escaneo, confirmación y registro contra el API', (
      tester,
    ) async {
      final requests = <http.Request>[];
      final flujo = await _escanear(
        tester,
        handler: (request) async {
          requests.add(request);
          return http.Response(jsonEncode(_cuerpoUso()), 201);
        },
      );

      flujo.camara.onDetectado!('token-valido');
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('escaneo_confirmar_uso')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmar_uso_confirmar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmar_uso_registrado')), findsOneWidget);
      expect(requests, hasLength(1));

      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['qrToken'], 'token-valido');
      expect(body['idempotencyKey'], isA<String>());
      expect(body['idempotencyKey'], isNotEmpty);
    });

    testWidgets('sin conexión encola y un reintento sincroniza con la misma clave', (
      tester,
    ) async {
      final flujo = await _escanear(
        tester,
        handler: (_) async => throw http.ClientException('sin red'),
      );

      flujo.camara.onDetectado!('token-valido');
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('escaneo_confirmar_uso')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmar_uso_confirmar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmar_uso_pendiente')), findsOneWidget);
      expect(flujo.cola.items, hasLength(1));
      expect(flujo.cola.items.single.qrToken, 'token-valido');
    });

    testWidgets('la sincronización reenvía el pendiente con su clave original', (
      tester,
    ) async {
      final cola = FakeColaUsosPendientes();
      final offline = RegistrarUsoUseCase(
        UsosRepositoryImpl(
          _http(
            MockClient((_) async => throw http.ClientException('sin red')),
          ),
        ),
        cola,
      );

      await offline(qrToken: 'token-valido', equipo: _equipo);

      expect(cola.items, hasLength(1));
      final clave = cola.items.single.idempotencyKey;

      final requests = <http.Request>[];
      final sincronizar = SincronizarUsosPendientesUseCase(
        UsosRepositoryImpl(
          _http(
            MockClient((request) async {
              requests.add(request);
              return http.Response(jsonEncode(_cuerpoUso()), 201);
            }),
          ),
        ),
        cola,
      );

      final resultado = await sincronizar();

      expect(resultado.sincronizados, 1);
      expect(resultado.pendientesRestantes, 0);
      expect(cola.items, isEmpty);

      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['qrToken'], 'token-valido');
      expect(body['idempotencyKey'], clave);
    });
  });
}

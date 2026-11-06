import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/dominio/edicion_equipo.dart';
import 'package:scei_qr/dominio/equipo.dart';
import 'package:scei_qr/features/equipos/domain/repositories/equipos_repository.dart';
import 'package:scei_qr/features/equipos/domain/usecases/registrar_equipo_usecase.dart';

class FakeEquiposRepository implements EquiposRepository {
  FakeEquiposRepository({this.alRegistrar});

  Future<Equipo> Function(SolicitudAltaEquipo)? alRegistrar;
  int llamadas = 0;
  SolicitudAltaEquipo? ultimaSolicitud;

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    final handler = alRegistrar;
    if (handler == null) {
      return const Equipo(
        id: 12,
        identificador: 'LAB-PC-001',
        ubicacion: 'Fila A, Mesa 3',
        activo: true,
      );
    }
    return handler(solicitud);
  }

  @override
  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  }) async => throw UnimplementedError();

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async => throw UnimplementedError();

  @override
  Future<Equipo> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async => throw UnimplementedError();

  @override
  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo}) async =>
      throw UnimplementedError();

  @override
  Future<Equipo> regenerarQr(int id) async => throw UnimplementedError();

  @override
  Future<Uint8List> obtenerImagenQr(int id) async =>
      throw UnimplementedError();
}

void main() {
  const valida = SolicitudAltaEquipo(
    identificador: 'LAB-PC-001',
    laboratorio: 'Laboratorio de Cómputo 1',
    ubicacion: 'Fila A, Mesa 3',
    descripcion: 'Dell OptiPlex 3080',
  );

  test('delega en el repositorio cuando la solicitud es válida', () async {
    final repo = FakeEquiposRepository();
    final useCase = RegistrarEquipoUseCase(repo);

    final equipo = await useCase(valida);

    expect(equipo.identificador, 'LAB-PC-001');
    expect(repo.llamadas, 1);
    expect(repo.ultimaSolicitud, same(valida));
  });

  test('no llama al repositorio si falta un dato obligatorio', () async {
    final repo = FakeEquiposRepository();
    final useCase = RegistrarEquipoUseCase(repo);

    await expectLater(
      useCase(
        const SolicitudAltaEquipo(
          identificador: '',
          laboratorio: 'Laboratorio de Cómputo 1',
          ubicacion: 'Fila A',
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(repo.llamadas, 0);
  });

  test('propaga el conflicto de unicidad del identificador', () async {
    final repo = FakeEquiposRepository(
      alRegistrar: (_) async => throw const ConflictException(
        'El código "LAB-PC-001" ya está registrado',
        campo: 'identificador',
      ),
    );
    final useCase = RegistrarEquipoUseCase(repo);

    await expectLater(
      useCase(valida),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.campo,
          'campo',
          'identificador',
        ),
      ),
    );
  });
}

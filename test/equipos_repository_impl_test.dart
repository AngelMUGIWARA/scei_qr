import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_equipo.dart';
import 'package:scei_qr/features/equipos/data/datasources/equipos_remote_data_source.dart';
import 'package:scei_qr/features/equipos/data/models/equipo_model.dart';
import 'package:scei_qr/features/equipos/data/repositories/equipos_repository_impl.dart';

class FakeRemoteDataSource implements EquiposRemoteDataSource {
  FakeRemoteDataSource({this.respuesta, this.error});

  EquipoModel? respuesta;
  Object? error;
  int llamadas = 0;
  SolicitudAltaEquipo? ultimaSolicitud;

  @override
  Future<EquipoModel> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    if (error != null) throw error!;
    return respuesta!;
  }
}

void main() {
  const solicitud = SolicitudAltaEquipo(
    identificador: 'LAB-PC-001',
    laboratorio: 'Laboratorio de Cómputo 1',
    ubicacion: 'Fila A, Mesa 3',
    descripcion: 'Dell OptiPlex 3080',
  );

  test('mapea el DTO del backend a la entidad de dominio', () async {
    final remote = FakeRemoteDataSource(
      respuesta: const EquipoModel(
        id: 12,
        identificador: 'LAB-PC-001',
        ubicacion: 'Fila A, Mesa 3',
        descripcion: 'Dell OptiPlex 3080',
        activo: true,
        fechaAlta: null,
      ),
    );
    final repo = EquiposRepositoryImpl(remote);

    final equipo = await repo.registrarEquipo(solicitud);

    expect(equipo.id, 12);
    expect(equipo.identificador, 'LAB-PC-001');
    expect(equipo.ubicacion, 'Fila A, Mesa 3');
    expect(equipo.descripcion, 'Dell OptiPlex 3080');
    expect(equipo.activo, isTrue);
    expect(remote.ultimaSolicitud, same(solicitud));
  });

  test('propaga el ConflictException del datasource', () async {
    final remote = FakeRemoteDataSource(
      error: const ConflictException(
        'El código "LAB-PC-001" ya está registrado',
        campo: 'identificador',
      ),
    );
    final repo = EquiposRepositoryImpl(remote);

    await expectLater(
      repo.registrarEquipo(solicitud),
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

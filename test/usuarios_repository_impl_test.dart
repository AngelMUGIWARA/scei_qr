import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_tecnico.dart';
import 'package:scei_qr/dominio/edicion_tecnico.dart';
import 'package:scei_qr/features/usuarios/data/datasources/usuarios_remote_data_source.dart';
import 'package:scei_qr/features/usuarios/data/models/tecnico_model.dart';
import 'package:scei_qr/features/usuarios/data/repositories/usuarios_repository_impl.dart';

class FakeRemoteDataSource implements UsuariosRemoteDataSource {
  FakeRemoteDataSource({this.respuesta, this.error});

  TecnicoModel? respuesta;
  Object? error;
  int llamadas = 0;
  SolicitudAltaTecnico? ultimaSolicitud;

  @override
  Future<TecnicoModel> registrarTecnico(SolicitudAltaTecnico solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    if (error != null) throw error!;
    return respuesta!;
  }

  @override
  Future<List<TecnicoModel>> listarTecnicos({
    String? busqueda,
    bool? activo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TecnicoModel> editarTecnico(
    int id,
    SolicitudEdicionTecnico solicitud,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TecnicoModel> cambiarEstadoTecnico(
    int id, {
    required bool activo,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  const solicitud = SolicitudAltaTecnico(
    nombreCompleto: 'Carlos Mena',
    correo: 'carlos.mena@utez.edu.mx',
    usuario: 'cmena',
    contrasenaInicial: 'Password123!',
  );

  test('mapea el DTO del backend a la entidad de dominio', () async {
    final remote = FakeRemoteDataSource(
      respuesta: TecnicoModel(
        id: 7,
        username: 'cmena',
        fullName: 'Carlos Mena',
        correo: 'carlos.mena@utez.edu.mx',
        activo: true,
        createdAt: DateTime.utc(2026, 11, 5, 12),
      ),
    );
    final repo = UsuariosRepositoryImpl(remote);

    final tecnico = await repo.registrarTecnico(solicitud);

    expect(tecnico.id, 7);
    expect(tecnico.usuario, 'cmena');
    expect(tecnico.nombreCompleto, 'Carlos Mena');
    expect(tecnico.correo, 'carlos.mena@utez.edu.mx');
    expect(tecnico.activo, isTrue);
    expect(tecnico.fechaAlta, DateTime.utc(2026, 11, 5, 12));
    expect(remote.ultimaSolicitud, same(solicitud));
  });

  test('propaga el ConflictException del datasource', () async {
    final remote = FakeRemoteDataSource(
      error: const ConflictException(
        'El usuario "cmena" ya existe',
        campo: 'usuario',
      ),
    );
    final repo = UsuariosRepositoryImpl(remote);

    await expectLater(
      repo.registrarTecnico(solicitud),
      throwsA(
        isA<ConflictException>().having((e) => e.campo, 'campo', 'usuario'),
      ),
    );
  });
}

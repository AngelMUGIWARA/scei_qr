import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_tecnico.dart';
import 'package:scei_qr/dominio/edicion_tecnico.dart';
import 'package:scei_qr/dominio/tecnico.dart';
import 'package:scei_qr/features/usuarios/domain/repositories/usuarios_repository.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/cambiar_estado_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/editar_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/listar_tecnicos_usecase.dart';

class FakeUsuariosRepository implements UsuariosRepository {
  FakeUsuariosRepository({
    this.tecnicos = const [],
    this.alListar,
    this.alEditar,
    this.alCambiarEstado,
  });

  final List<Tecnico> tecnicos;
  final Future<List<Tecnico>> Function(String? busqueda, bool? activo)?
  alListar;
  final Future<Tecnico> Function(int id, SolicitudEdicionTecnico solicitud)?
  alEditar;
  final Future<Tecnico> Function(int id, bool activo)? alCambiarEstado;

  int listarLlamadas = 0;
  int editarLlamadas = 0;
  int cambiarEstadoLlamadas = 0;
  String? ultimaBusqueda;
  bool? ultimoFiltroActivo;
  int? ultimoId;
  SolicitudEdicionTecnico? ultimaSolicitud;
  bool? ultimoActivo;

  @override
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud) {
    throw UnimplementedError();
  }

  @override
  Future<List<Tecnico>> listarTecnicos({String? busqueda, bool? activo}) async {
    listarLlamadas++;
    ultimaBusqueda = busqueda;
    ultimoFiltroActivo = activo;
    final handler = alListar;
    if (handler != null) return handler(busqueda, activo);
    return tecnicos;
  }

  @override
  Future<Tecnico> editarTecnico(
    int id,
    SolicitudEdicionTecnico solicitud,
  ) async {
    editarLlamadas++;
    ultimoId = id;
    ultimaSolicitud = solicitud;
    final handler = alEditar;
    if (handler != null) return handler(id, solicitud);
    return tecnicoDePrueba();
  }

  @override
  Future<Tecnico> cambiarEstadoTecnico(int id, {required bool activo}) async {
    cambiarEstadoLlamadas++;
    ultimoId = id;
    ultimoActivo = activo;
    final handler = alCambiarEstado;
    if (handler != null) return handler(id, activo);
    return tecnicoDePrueba(activo: activo);
  }
}

Tecnico tecnicoDePrueba({bool activo = true}) => Tecnico(
  id: 7,
  nombreCompleto: 'Carlos Mena',
  correo: 'carlos.mena@utez.edu.mx',
  usuario: 'cmena',
  activo: activo,
);

void main() {
  group('ListarTecnicosUseCase', () {
    test('delega la búsqueda ya recortada', () async {
      final repo = FakeUsuariosRepository(tecnicos: [tecnicoDePrueba()]);
      final useCase = ListarTecnicosUseCase(repo);

      final tecnicos = await useCase(busqueda: '  Carlos  ');

      expect(tecnicos, hasLength(1));
      expect(repo.listarLlamadas, 1);
      expect(repo.ultimaBusqueda, 'Carlos');
    });

    test('envía null cuando la búsqueda está vacía', () async {
      final repo = FakeUsuariosRepository();
      final useCase = ListarTecnicosUseCase(repo);

      await useCase(busqueda: '   ');

      expect(repo.ultimaBusqueda, isNull);
    });

    test('delega el filtro de estado al repositorio', () async {
      final repo = FakeUsuariosRepository(tecnicos: [tecnicoDePrueba()]);
      final useCase = ListarTecnicosUseCase(repo);

      await useCase(activo: false);

      expect(repo.ultimoFiltroActivo, isFalse);
    });
  });

  group('EditarTecnicoUseCase', () {
    const valida = SolicitudEdicionTecnico(
      nombreCompleto: 'Carlos Mena',
      correo: 'carlos.mena@utez.edu.mx',
      contrasenaNueva: 'NuevaPassword123!',
    );

    test('delega en el repositorio cuando la solicitud es válida', () async {
      final repo = FakeUsuariosRepository();
      final useCase = EditarTecnicoUseCase(repo);

      final tecnico = await useCase(7, valida);

      expect(tecnico.id, 7);
      expect(repo.editarLlamadas, 1);
      expect(repo.ultimoId, 7);
      expect(repo.ultimaSolicitud, same(valida));
    });

    test('no llama al repositorio si la solicitud es inválida', () async {
      final repo = FakeUsuariosRepository();
      final useCase = EditarTecnicoUseCase(repo);

      await expectLater(
        useCase(
          7,
          const SolicitudEdicionTecnico(
            nombreCompleto: '',
            correo: 'sin-arroba',
            contrasenaNueva: 'corta',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(repo.editarLlamadas, 0);
    });

    test('propaga el conflicto del repositorio', () async {
      final repo = FakeUsuariosRepository(
        alEditar: (_, _) async => throw const ConflictException(
          'El correo ya existe',
          campo: 'correo',
        ),
      );
      final useCase = EditarTecnicoUseCase(repo);

      await expectLater(
        useCase(7, valida),
        throwsA(
          isA<ConflictException>().having((e) => e.campo, 'campo', 'correo'),
        ),
      );
    });
  });

  group('CambiarEstadoTecnicoUseCase', () {
    test('delega la activación al repositorio', () async {
      final repo = FakeUsuariosRepository();
      final useCase = CambiarEstadoTecnicoUseCase(repo);

      final tecnico = await useCase(7, activo: false);

      expect(tecnico.activo, isFalse);
      expect(repo.cambiarEstadoLlamadas, 1);
      expect(repo.ultimoId, 7);
      expect(repo.ultimoActivo, isFalse);
    });
  });
}

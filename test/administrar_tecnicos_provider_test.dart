import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/cambiar_estado_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/listar_tecnicos_usecase.dart';
import 'package:scei_qr/features/usuarios/presentation/providers/administrar_tecnicos_provider.dart';

import 'fakes_usuarios.dart';

void main() {
  AdministrarTecnicosProvider crearProvider(FakeUsuariosRepository repo) {
    return AdministrarTecnicosProvider(
      listarTecnicosUseCase: ListarTecnicosUseCase(repo),
      cambiarEstadoTecnicoUseCase: CambiarEstadoTecnicoUseCase(repo),
    );
  }

  group('AdministrarTecnicosProvider.cargar', () {
    test('pasa por loading y guarda los técnicos', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);
      final estados = <TecnicosStatus>[];
      provider.addListener(() => estados.add(provider.status));

      await provider.cargar();

      expect(estados, [TecnicosStatus.loading, TecnicosStatus.success]);
      expect(provider.tecnicos, hasLength(2));
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(repo.listarLlamadas, 1);
    });

    test('expone el mensaje cuando falla la carga', () async {
      final repo = FakeUsuariosRepository(
        alListar: (_, _) async => throw const NetworkException(
          'No se pudo conectar con el servidor.',
        ),
      );
      final provider = crearProvider(repo);

      await provider.cargar();

      expect(provider.status, TecnicosStatus.error);
      expect(provider.errorMessage, 'No se pudo conectar con el servidor.');
      expect(provider.tecnicos, isEmpty);
    });
  });

  group('AdministrarTecnicosProvider.buscar', () {
    test('recorta el término y lo delega al caso de uso', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);

      await provider.buscar('  Lucía  ');

      expect(repo.ultimaBusqueda, 'Lucía');
      expect(provider.tecnicos, hasLength(1));
      expect(provider.tecnicos.single.nombreCompleto, 'Lucía López');
    });

    test('sin término vuelve a listar todos', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);
      await provider.buscar('Lucía');

      await provider.buscar('   ');

      expect(repo.ultimaBusqueda, isNull);
      expect(provider.tecnicos, hasLength(2));
    });
  });

  group('AdministrarTecnicosProvider.cambiarFiltro', () {
    test('filtra activos y envía activo=true', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);

      await provider.cambiarFiltro(FiltroEstadoTecnicos.activos);

      expect(repo.ultimoFiltroActivo, isTrue);
      expect(provider.filtro, FiltroEstadoTecnicos.activos);
      expect(provider.tecnicos, hasLength(1));
      expect(provider.tecnicos.single.activo, isTrue);
    });

    test('filtra inactivos y envía activo=false', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);

      await provider.cambiarFiltro(FiltroEstadoTecnicos.inactivos);

      expect(repo.ultimoFiltroActivo, isFalse);
      expect(provider.tecnicos, hasLength(1));
      expect(provider.tecnicos.single.activo, isFalse);
    });

    test('no recarga si se elige el mismo filtro', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);
      await provider.cargar();

      await provider.cambiarFiltro(FiltroEstadoTecnicos.todos);

      expect(repo.listarLlamadas, 1);
    });

    test('mantiene la búsqueda al cambiar de filtro', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);
      await provider.buscar('Carlos');

      await provider.cambiarFiltro(FiltroEstadoTecnicos.activos);

      expect(repo.ultimaBusqueda, 'Carlos');
      expect(repo.ultimoFiltroActivo, isTrue);
      expect(provider.tecnicos.single.nombreCompleto, 'Carlos Mena');
    });
  });

  group('AdministrarTecnicosProvider.cambiarEstado', () {
    test('actualiza el técnico en la lista al desactivarlo', () async {
      final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
      final provider = crearProvider(repo);
      await provider.cargar();

      final ok = await provider.cambiarEstado(
        provider.tecnicos.first,
        activo: false,
      );

      expect(ok, isTrue);
      expect(repo.cambiarEstadoLlamadas, 1);
      expect(repo.ultimoId, 7);
      expect(repo.ultimoActivo, isFalse);
      expect(provider.tecnicos.first.activo, isFalse);
      expect(provider.hayCambioEnCurso, isFalse);
    });

    test('mantiene la lista y expone el error si falla el cambio', () async {
      final repo = FakeUsuariosRepository(
        tecnicos: tecnicosDePrueba(),
        alCambiarEstado: (_, _) async =>
            throw const ForbiddenException('Sin permisos.'),
      );
      final provider = crearProvider(repo);
      await provider.cargar();

      final ok = await provider.cambiarEstado(
        provider.tecnicos.first,
        activo: false,
      );

      expect(ok, isFalse);
      expect(provider.errorMessage, 'Sin permisos.');
      expect(provider.tecnicos.first.activo, isTrue);
      expect(provider.hayCambioEnCurso, isFalse);
    });

    test(
      'quita de la lista al desactivar cuando el filtro es activos',
      () async {
        final repo = FakeUsuariosRepository(tecnicos: tecnicosDePrueba());
        final provider = crearProvider(repo);
        await provider.cambiarFiltro(FiltroEstadoTecnicos.activos);
        final tecnico = provider.tecnicos.single;

        final ok = await provider.cambiarEstado(tecnico, activo: false);

        expect(ok, isTrue);
        expect(provider.tecnicos, isEmpty);
      },
    );
  });
}

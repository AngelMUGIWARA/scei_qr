import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/edicion_tecnico.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/editar_tecnico_usecase.dart';
import 'package:scei_qr/features/usuarios/presentation/providers/editar_tecnico_provider.dart';

import 'fakes_usuarios.dart';

void main() {
  const solicitud = SolicitudEdicionTecnico(
    nombreCompleto: 'Carlos Mena',
    correo: 'carlos.mena@utez.edu.mx',
    contrasenaNueva: 'NuevaPassword123!',
  );

  EditarTecnicoProvider crearProvider(FakeUsuariosRepository repo) {
    return EditarTecnicoProvider(
      editarTecnicoUseCase: EditarTecnicoUseCase(repo),
    );
  }

  group('EditarTecnicoProvider.editar', () {
    test('pasa por loading y devuelve el técnico actualizado', () async {
      final repo = FakeUsuariosRepository(tecnicos: [tecnicoDePrueba()]);
      final provider = crearProvider(repo);
      final estados = <EditarTecnicoStatus>[];
      provider.addListener(() => estados.add(provider.status));

      final tecnico = await provider.editar(7, solicitud);

      expect(estados, [
        EditarTecnicoStatus.loading,
        EditarTecnicoStatus.success,
      ]);
      expect(tecnico, isNotNull);
      expect(provider.tecnico!.nombreCompleto, 'Carlos Mena');
      expect(repo.editarLlamadas, 1);
    });

    test('expone campo y mensaje cuando hay conflicto', () async {
      final repo = FakeUsuariosRepository(
        alEditar: (_, _) async => throw const ConflictException(
          'El correo ya existe',
          campo: 'correo',
        ),
      );
      final provider = crearProvider(repo);

      final tecnico = await provider.editar(7, solicitud);

      expect(tecnico, isNull);
      expect(provider.status, EditarTecnicoStatus.error);
      expect(provider.errorMessage, 'El correo ya existe');
      expect(provider.campoError, 'correo');
    });

    test('no llama al repositorio si la solicitud es inválida', () async {
      final repo = FakeUsuariosRepository();
      final provider = crearProvider(repo);

      await provider.editar(
        7,
        const SolicitudEdicionTecnico(nombreCompleto: '', correo: 'correo'),
      );

      expect(provider.status, EditarTecnicoStatus.error);
      expect(provider.errorMessage, isNotNull);
      expect(repo.editarLlamadas, 0);
    });

    test('clearError limpia el mensaje y el campo', () async {
      final repo = FakeUsuariosRepository(
        alEditar: (_, _) async => throw const ConflictException(
          'El usuario ya existe',
          campo: 'usuario',
        ),
      );
      final provider = crearProvider(repo);
      await provider.editar(7, solicitud);

      provider.clearError();

      expect(provider.errorMessage, isNull);
      expect(provider.campoError, isNull);
      expect(provider.status, EditarTecnicoStatus.idle);
    });
  });
}

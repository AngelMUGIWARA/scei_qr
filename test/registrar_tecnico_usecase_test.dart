import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/alta_tecnico.dart';
import 'package:scei_qr/dominio/tecnico.dart';
import 'package:scei_qr/features/usuarios/domain/repositories/usuarios_repository.dart';
import 'package:scei_qr/features/usuarios/domain/usecases/registrar_tecnico_usecase.dart';

class FakeUsuariosRepository implements UsuariosRepository {
  FakeUsuariosRepository({this.alRegistrar});

  Future<Tecnico> Function(SolicitudAltaTecnico)? alRegistrar;
  int llamadas = 0;
  SolicitudAltaTecnico? ultimaSolicitud;

  @override
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud) async {
    llamadas++;
    ultimaSolicitud = solicitud;
    final handler = alRegistrar;
    if (handler == null) {
      return const Tecnico(
        id: 7,
        nombreCompleto: 'Carlos Mena',
        correo: 'carlos.mena@utez.edu.mx',
        usuario: 'cmena',
        activo: true,
      );
    }
    return handler(solicitud);
  }
}

void main() {
  const valida = SolicitudAltaTecnico(
    nombreCompleto: 'Carlos Mena',
    correo: 'carlos.mena@utez.edu.mx',
    usuario: 'cmena',
    contrasenaInicial: 'Password123!',
  );

  test('delega en el repositorio cuando la solicitud es válida', () async {
    final repo = FakeUsuariosRepository();
    final useCase = RegistrarTecnicoUseCase(repo);

    final tecnico = await useCase(valida);

    expect(tecnico.usuario, 'cmena');
    expect(repo.llamadas, 1);
    expect(repo.ultimaSolicitud, same(valida));
  });

  test('no llama al repositorio si la solicitud es inválida', () async {
    final repo = FakeUsuariosRepository();
    final useCase = RegistrarTecnicoUseCase(repo);

    await expectLater(
      useCase(
        const SolicitudAltaTecnico(
          nombreCompleto: '',
          correo: 'sin-arroba',
          usuario: '',
          contrasenaInicial: '',
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(repo.llamadas, 0);
  });

  test('propaga el conflicto del repositorio', () async {
    final repo = FakeUsuariosRepository(
      alRegistrar: (_) async =>
          throw const ConflictException('El correo ya existe', campo: 'correo'),
    );
    final useCase = RegistrarTecnicoUseCase(repo);

    await expectLater(
      useCase(valida),
      throwsA(
        isA<ConflictException>().having((e) => e.campo, 'campo', 'correo'),
      ),
    );
  });
}

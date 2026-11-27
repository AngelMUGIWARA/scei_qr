import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scei_qr/core/errors/app_exception.dart';
import 'package:scei_qr/dominio/incidencia.dart';
import 'package:scei_qr/dominio/nueva_incidencia.dart';
import 'package:scei_qr/features/incidencias/domain/repositories/incidencias_repository.dart';
import 'package:scei_qr/features/incidencias/domain/usecases/reportar_incidencia_usecase.dart';
import 'package:scei_qr/features/incidencias/presentation/providers/reportar_incidencia_provider.dart';

import 'fakes_incidencias.dart';

/// Repositorio que no responde hasta que el test lo indique.
class _Lento implements IncidenciasRepository {
  final Completer<Incidencia> espera = Completer<Incidencia>();
  int llamadas = 0;

  @override
  Future<Incidencia> reportarIncidencia(NuevaIncidencia datos) {
    llamadas++;
    return espera.future;
  }
}

ReportarIncidenciaProvider _provider(IncidenciasRepository repo) =>
    ReportarIncidenciaProvider(ReportarIncidenciaUseCase(repo), equipoDePrueba);

/// Escribe una descripción válida sin tocar la UI.
void _escribir(ReportarIncidenciaProvider provider, [String? texto]) =>
    provider.cambiarDescripcion(texto ?? 'La pantalla parpadea');

void main() {
  group('ReportarIncidenciaProvider — HU-AL-06 (formulario)', () {
    test('arranca sin tipo seleccionado y sin descripción', () {
      final provider = _provider(FakeIncidenciasRepository());

      expect(provider.status, ReporteIncidenciaStatus.formulario);
      expect(provider.tipo, isNull);
      expect(provider.descripcion, isEmpty);
      expect(provider.descripcionLista, isFalse);
      expect(provider.incidencia, isNull);
      expect(provider.error, isNull);
    });

    test('descripción vacía no envía nada', () async {
      final repo = FakeIncidenciasRepository();
      final provider = _provider(repo)
        ..cambiarTipo(TipoProblema.hardware)
        ..cambiarDescripcion('');

      await provider.enviar();

      expect(repo.llamadas, 0);
      expect(provider.status, ReporteIncidenciaStatus.formulario);
    });

    test('descripción solo con espacios no envía nada', () async {
      final repo = FakeIncidenciasRepository();
      final provider = _provider(repo)
        ..cambiarTipo(TipoProblema.hardware)
        ..cambiarDescripcion('        \n  ');

      await provider.enviar();

      expect(repo.llamadas, 0);
      expect(provider.status, ReporteIncidenciaStatus.formulario);
    });

    test(
      'con descripción pero sin tipo no envía nada (tipo obligatorio)',
      () async {
        final repo = FakeIncidenciasRepository();
        final provider = _provider(repo)
          ..cambiarDescripcion('Se traba al abrir');

        await provider.enviar();

        expect(repo.llamadas, 0);
        expect(provider.tipo, isNull);
        expect(provider.validarTipo(), 'Elige el tipo de problema.');
      },
    );

    test('con ambos campos envía el equipo, el tipo y la descripción '
        'recortada', () async {
      final repo = FakeIncidenciasRepository();
      final provider = _provider(repo)
        ..cambiarTipo(TipoProblema.software)
        ..cambiarDescripcion('  No enciende el monitor  ');

      await provider.enviar();

      expect(repo.llamadas, 1);
      expect(repo.ultimoEnvio!.equipoId, equipoDePrueba.id);
      expect(repo.ultimoEnvio!.tipo, TipoProblema.software);
      expect(repo.ultimoEnvio!.descripcion, 'No enciende el monitor');
    });

    test('éxito: guarda la incidencia con su folio', () async {
      final repo = FakeIncidenciasRepository()
        ..incidencia = incidenciaDePrueba(id: 42);
      final provider = _provider(repo)..cambiarTipo(TipoProblema.hardware);
      _escribir(provider);

      await provider.enviar();

      expect(provider.status, ReporteIncidenciaStatus.enviado);
      expect(provider.incidencia!.folio, 'INC-000042');
      expect(provider.error, isNull);
      expect(provider.reintentable, isFalse);
    });

    test('doble toque hace una sola petición', () async {
      final lento = _Lento();
      final provider = _provider(lento)..cambiarTipo(TipoProblema.red);
      _escribir(provider);

      final primero = provider.enviar();
      final segundo = provider.enviar();

      // Mientras está enviando el formulario queda bloqueado.
      expect(provider.status, ReporteIncidenciaStatus.enviando);
      expect(lento.llamadas, 1);

      lento.espera.complete(incidenciaDePrueba());
      await Future.wait([primero, segundo]);

      // Ni el segundo toque ni una llegada tardía lo reenvían.
      expect(lento.llamadas, 1);
      expect(provider.status, ReporteIncidenciaStatus.enviado);
      await provider.enviar();
      expect(lento.llamadas, 1);
    });

    test('sin conexión informa el error y permite reintentar', () async {
      final repo = FakeIncidenciasRepository(error: const NetworkException());
      final provider = _provider(repo)..cambiarTipo(TipoProblema.hardware);
      _escribir(provider);

      await provider.enviar();

      expect(provider.status, ReporteIncidenciaStatus.error);
      expect(provider.error, const NetworkException().message);
      expect(provider.reintentable, isTrue);
    });

    test('error de servidor también permite reintentar', () async {
      final repo = FakeIncidenciasRepository(error: const ServerException());
      final provider = _provider(repo)..cambiarTipo(TipoProblema.hardware);
      _escribir(provider);

      await provider.enviar();

      expect(provider.status, ReporteIncidenciaStatus.error);
      expect(provider.reintentable, isTrue);
    });

    test('error del negocio (404/422) no ofrece reintentar', () async {
      final repo = FakeIncidenciasRepository(
        error: const NotFoundException(
          'El equipo no existe o está dado de baja.',
        ),
      );
      final provider = _provider(repo)..cambiarTipo(TipoProblema.hardware);
      _escribir(provider);

      await provider.enviar();

      expect(provider.status, ReporteIncidenciaStatus.error);
      expect(provider.reintentable, isFalse);
      expect(provider.error, 'El equipo no existe o está dado de baja.');
    });

    test('reintentar reenvía los mismos datos y puede completarse', () async {
      final repo = FakeIncidenciasRepository(error: const NetworkException())
        ..incidencia = incidenciaDePrueba(id: 7);
      final provider = _provider(repo)..cambiarTipo(TipoProblema.otro);
      _escribir(provider, 'Se reinicia solo');

      await provider.enviar();
      expect(provider.status, ReporteIncidenciaStatus.error);

      // El backend vuelve: ya no falla.
      repo.error = null;
      await provider.reintentar();

      expect(repo.llamadas, 2);
      expect(repo.ultimoEnvio!.tipo, TipoProblema.otro);
      expect(repo.ultimoEnvio!.descripcion, 'Se reinicia solo');
      expect(provider.status, ReporteIncidenciaStatus.enviado);
      expect(provider.incidencia!.folio, 'INC-000007');
    });

    test(
      '"Editar reporte" vuelve al formulario conservando los datos',
      () async {
        final repo = FakeIncidenciasRepository(error: const NetworkException());
        final provider = _provider(repo)..cambiarTipo(TipoProblema.software);
        _escribir(provider, 'El teclado no responde');

        await provider.enviar();
        expect(provider.status, ReporteIncidenciaStatus.error);

        provider.volverAlFormulario();

        expect(provider.status, ReporteIncidenciaStatus.formulario);
        expect(provider.error, isNull);
        // Regresión: el texto y el tipo escritos no se pierden.
        expect(provider.descripcion, 'El teclado no responde');
        expect(provider.tipo, TipoProblema.software);
        expect(provider.descripcionLista, isTrue);
      },
    );

    test('mientras envía no se editan los campos', () async {
      final lento = _Lento();
      final provider = _provider(lento)..cambiarTipo(TipoProblema.hardware);
      _escribir(provider);

      final pendiente = provider.enviar();
      provider.cambiarTipo(TipoProblema.software);
      provider.cambiarDescripcion('otro texto');

      expect(provider.tipo, TipoProblema.hardware);
      expect(provider.descripcion, 'La pantalla parpadea');

      lento.espera.complete(incidenciaDePrueba());
      await pendiente;
    });

    test('los mensajes de validación cubren descripción y tipo', () {
      final provider = _provider(FakeIncidenciasRepository());

      expect(provider.validarDescripcion(''), 'La descripción es obligatoria.');
      expect(provider.validarDescripcion('   '), isNotNull);
      expect(provider.validarDescripcion('texto'), isNull);
      expect(provider.validarTipo(), isNotNull);

      provider.cambiarTipo(TipoProblema.red);

      expect(provider.validarTipo(), isNull);
    });

    test('la descripción tiene un límite de longitud', () {
      expect(ReportarIncidenciaProvider.maxDescripcion, 500);
    });
  });
}

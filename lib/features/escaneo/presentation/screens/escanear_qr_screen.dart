import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/equipo.dart';
import '../../../equipos/domain/repositories/equipos_repository.dart';
import '../../../equipos/domain/usecases/validar_qr_usecase.dart';
import '../../data/permiso_camara_handler.dart';
import '../../domain/permiso_camara.dart';
import '../providers/escaneo_provider.dart';

/// Constructor de la vista de cámara. Permite inyectar una cámara falsa en
/// los tests de widgets (la real necesita dispositivo/emulador).
typedef CamaraBuilder = Widget Function(
  BuildContext context,
  void Function(String valor) onDetectado,
);

/// HU-AL-02: escaneo del QR de un equipo con la cámara del teléfono.
///
/// Muestra la cámara mientras se pide el permiso, valida el QR leído
/// contra el backend y muestra el equipo identificado (o el error con
/// opción de reintentar).
class EscanearQrScreen extends StatelessWidget {
  const EscanearQrScreen({
    super.key,
    this.validarQrUseCase,
    this.permisoCamara,
    this.camaraBuilder,
  });

  final ValidarQrUseCase? validarQrUseCase;
  final PermisoCamara? permisoCamara;

  /// Reemplaza la cámara real (tests / preview).
  final CamaraBuilder? camaraBuilder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final repository = validarQrUseCase == null
            ? context.read<EquiposRepository>()
            : null;
        return EscaneoProvider(
          validarQrUseCase:
              validarQrUseCase ?? ValidarQrUseCase(repository!),
          permisoCamara: permisoCamara ?? const PermisoCamaraHandler(),
        )..iniciar();
      },
      child: _EscanearQrBody(camaraBuilder: camaraBuilder),
    );
  }
}

class _EscanearQrBody extends StatelessWidget {
  const _EscanearQrBody({this.camaraBuilder});

  final CamaraBuilder? camaraBuilder;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EscaneoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código QR')),
      body: _contenido(context, provider),
    );
  }

  Widget _contenido(BuildContext context, EscaneoProvider provider) {
    switch (provider.status) {
      case EscaneoStatus.solicitandoPermiso:
        return const _CentroCarga(
          key: Key('escaneo_solicitando_permiso'),
          mensaje: 'Solicitando permiso de cámara…',
        );

      case EscaneoStatus.permisoDenegado:
        return _PermisoDenegado(
          key: const Key('escaneo_permiso_denegado'),
          onAbrirAjustes: provider.abrirAjustes,
          onReintentar: provider.iniciar,
        );

      case EscaneoStatus.escaneando:
        return _VistaCamara(
          camaraBuilder: camaraBuilder,
          onDetectado: provider.procesarQr,
        );

      case EscaneoStatus.validando:
        return Stack(
          children: [
            _VistaCamara(
              camaraBuilder: camaraBuilder,
              onDetectado: provider.procesarQr,
            ),
            const ColoredBox(
              color: Color(0x99000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      key: Key('escaneo_validando_spinner'),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Validando código…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case EscaneoStatus.equipoEncontrado:
        return _EquipoEncontrado(
          key: const Key('escaneo_equipo_encontrado'),
          equipo: provider.equipo!,
          onEscanearOtro: provider.reintentar,
        );

      case EscaneoStatus.errorQr:
        return _ErrorQr(
          key: const Key('escaneo_error_qr'),
          mensaje: provider.errorQr ?? 'El código QR no es válido.',
          onReintentar: provider.reintentar,
        );
    }
  }
}

/// Cámara por defecto: `MobileScanner` real.
Widget _camaraReal(BuildContext context, void Function(String) onDetectado) {
  return MobileScanner(
    key: const Key('escaneo_camara'),
    onDetect: (capture) {
      final valor = capture.barcodes.isNotEmpty
          ? capture.barcodes.first.rawValue
          : null;
      if (valor != null && valor.isNotEmpty) onDetectado(valor);
    },
  );
}

class _VistaCamara extends StatelessWidget {
  const _VistaCamara({required this.camaraBuilder, required this.onDetectado});

  final CamaraBuilder? camaraBuilder;
  final void Function(String valor) onDetectado;

  @override
  Widget build(BuildContext context) {
    final construir = camaraBuilder ?? _camaraReal;
    return Stack(
      fit: StackFit.expand,
      children: [
        construir(context, onDetectado),
        // Marco de apuntado + instrucción (CA: responde en pocos segundos).
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MarcoEscaneo(),
              SizedBox(height: 24),
              Text(
                'Apunta al código QR del equipo',
                key: Key('escaneo_hint'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarcoEscaneo extends StatelessWidget {
  const _MarcoEscaneo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _PermisoDenegado extends StatelessWidget {
  const _PermisoDenegado({
    super.key,
    required this.onAbrirAjustes,
    required this.onReintentar,
  });

  final Future<void> Function() onAbrirAjustes;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Se necesita el permiso de cámara',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Para escanear el código QR del equipo, habilita el acceso a '
              'la cámara desde los ajustes de la aplicación:\n\n'
              'Ajustes → Aplicaciones → Scei Qr → Permiso → Cámara.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('escaneo_abrir_ajustes'),
              onPressed: () => onAbrirAjustes(),
              icon: const Icon(Icons.settings),
              label: const Text('Abrir ajustes'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('escaneo_reintentar_permiso'),
              onPressed: () => onReintentar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipoEncontrado extends StatelessWidget {
  const _EquipoEncontrado({
    super.key,
    required this.equipo,
    required this.onEscanearOtro,
  });

  final Equipo equipo;
  final VoidCallback onEscanearOtro;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            Text(
              'Equipo identificado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.computer, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      equipo.identificador,
                      key: const Key('escaneo_equipo_identificador'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (equipo.nombreVisible != equipo.identificador) ...[
                      const SizedBox(height: 4),
                      Text(
                        equipo.nombreVisible,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // CA: identificador + laboratorio. El contrato actual no
                    // expone `laboratorio`; se muestra `ubicacion`.
                    Text(
                      'Ubicación: ${equipo.ubicacion}',
                      key: const Key('escaneo_equipo_ubicacion'),
                      textAlign: TextAlign.center,
                    ),
                    if ((equipo.descripcion ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        equipo.descripcion!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.outline),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              key: const Key('escaneo_escanear_otro'),
              onPressed: onEscanearOtro,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear otro código'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorQr extends StatelessWidget {
  const _ErrorQr({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Código QR no válido',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              key: const Key('escaneo_error_mensaje'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('escaneo_reintentar_qr'),
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentroCarga extends StatelessWidget {
  const _CentroCarga({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(mensaje),
        ],
      ),
    );
  }
}

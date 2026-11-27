import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/equipo.dart';
import '../../../../dominio/incidencia.dart';
import '../../domain/repositories/incidencias_repository.dart';
import '../../domain/usecases/reportar_incidencia_usecase.dart';
import '../providers/reportar_incidencia_provider.dart';

/// HU-AL-06: pantalla para reportar una incidencia en un equipo.
///
/// Se navega aquí desde [EscanearQrScreen] (ruta por escaneo directo) o
/// desde la tarjeta del uso activo en `UsoActivoCard` (ruta desde el
/// registro en curso). El [equipo] llega siempre como parámetro; el alumno
/// se vincula en el backend mediante el token de sesión.
class ReportarIncidenciaScreen extends StatelessWidget {
  const ReportarIncidenciaScreen({
    super.key,
    required this.equipo,
    this.useCase,
  });

  final Equipo equipo;

  /// Inyectable para tests; si es null se resuelve del árbol de providers.
  final ReportarIncidenciaUseCase? useCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final uc =
            useCase ??
            ReportarIncidenciaUseCase(context.read<IncidenciasRepository>());
        return ReportarIncidenciaProvider(uc, equipo);
      },
      child: const _ReportarIncidenciaBody(),
    );
  }
}

class _ReportarIncidenciaBody extends StatelessWidget {
  const _ReportarIncidenciaBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportarIncidenciaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidencia')),
      body: switch (provider.status) {
        ReporteIncidenciaStatus.formulario ||
        ReporteIncidenciaStatus.enviando => _Formulario(
          key: const Key('reporte_formulario'),
        ),
        ReporteIncidenciaStatus.enviado => _Confirmacion(
          key: const Key('reporte_confirmacion'),
          incidencia: provider.incidencia!,
          equipo: provider.equipo,
        ),
        ReporteIncidenciaStatus.error => _ErrorEnvio(
          key: const Key('reporte_error'),
          mensaje: provider.error ?? 'No se pudo enviar el reporte.',
          reintentable: provider.reintentable,
        ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario
// ─────────────────────────────────────────────────────────────────────────────

class _Formulario extends StatefulWidget {
  const _Formulario({super.key});

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionController;
  bool _intentoEnvio = false;

  @override
  void initState() {
    super.initState();
    // El provider es la fuente de verdad del formulario: cuando se vuelve
    // desde el estado de error este widget se vuelve a crear y debe
    // arrancar con lo que el alumno ya había escrito (CA HU-AL-06).
    _descripcionController = TextEditingController(
      text: context.read<ReportarIncidenciaProvider>().descripcion,
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportarIncidenciaProvider>();
    final enviando = provider.status == ReporteIncidenciaStatus.enviando;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta del equipo identificado (CA: "el equipo ya identificado").
            _TarjetaEquipo(equipo: provider.equipo),
            const SizedBox(height: 24),

            // Selector de tipo de problema (CA: hardware, software, red,
            // periféricos u otro). Obligatorio y sin preselección.
            Text(
              'Tipo de problema *',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _SelectorTipo(
              valorActual: provider.tipo,
              habilitado: !enviando,
              onCambio: provider.cambiarTipo,
            ),
            // El tipo es obligatorio: se avisa solo tras el primer intento
            // de envío (CA HU-AL-06).
            if (_intentoEnvio && provider.tipo == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  provider.validarTipo()!,
                  key: const Key('reporte_error_tipo'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Campo de descripción obligatoria (CA HU-AL-06).
            TextFormField(
              key: const Key('reporte_descripcion'),
              controller: _descripcionController,
              enabled: !enviando,
              maxLines: 4,
              maxLength: ReportarIncidenciaProvider.maxDescripcion,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción del problema *',
                hintText: 'Describe la falla con el mayor detalle posible…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: provider.cambiarDescripcion,
              validator: (valor) {
                if (!_intentoEnvio) return null;
                return provider.validarDescripcion(valor ?? '');
              },
            ),
            const SizedBox(height: 8),
            Text(
              '* Campo obligatorio',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 32),

            // Botón de envío — deshabilitado si falta la descripción
            // obligatoria o mientras se envía (CA HU-AL-06).
            enviando
                ? const Center(
                    key: Key('reporte_enviando'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Enviando reporte…'),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    key: const Key('reporte_boton_enviar'),
                    onPressed: !provider.descripcionLista
                        ? null
                        : () => _enviar(context, provider),
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar reporte'),
                  ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('reporte_boton_cancelar'),
              onPressed: enviando ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  void _enviar(BuildContext context, ReportarIncidenciaProvider provider) {
    setState(() => _intentoEnvio = true);

    // Valida campos obligatorios antes de enviar (CA HU-AL-06): la
    // descripción con el validator del campo y el tipo en el selector.
    if (!_formKey.currentState!.validate()) return;
    if (provider.tipo == null) return;

    provider.enviar();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selector de tipo de problema
// ─────────────────────────────────────────────────────────────────────────────

class _SelectorTipo extends StatelessWidget {
  const _SelectorTipo({
    required this.valorActual,
    required this.habilitado,
    required this.onCambio,
  });

  /// `null` cuando el alumno todavía no eligió (sin preselección).
  final TipoProblema? valorActual;
  final bool habilitado;
  final void Function(TipoProblema) onCambio;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TipoProblema.values.map((tipo) {
        final seleccionado = tipo == valorActual;
        return ChoiceChip(
          key: Key('reporte_tipo_${tipo.name}'),
          label: Text(tipo.etiqueta),
          selected: seleccionado,
          onSelected: habilitado ? (_) => onCambio(tipo) : null,
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmación con folio
// ─────────────────────────────────────────────────────────────────────────────

class _Confirmacion extends StatelessWidget {
  const _Confirmacion({
    super.key,
    required this.incidencia,
    required this.equipo,
  });

  final Incidencia incidencia;
  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            Text(
              'Reporte enviado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu incidencia fue registrada con el siguiente folio:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Folio de seguimiento (CA HU-AL-06).
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      incidencia.folio,
                      key: const Key('reporte_folio'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Folio de seguimiento',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _TarjetaResumen(incidencia: incidencia, equipo: equipo),
            const SizedBox(height: 32),

            FilledButton.icon(
              key: const Key('reporte_boton_listo'),
              onPressed: () {
                // Regresa a la pantalla de inicio del alumno vaciando el stack.
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.incidencia, required this.equipo});

  final Incidencia incidencia;
  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final identificador =
        incidencia.equipoIdentificador ?? equipo.identificador;
    final ubicacion = incidencia.equipoUbicacion ?? equipo.ubicacion;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              [
                    _Fila(
                      icono: Icons.computer,
                      etiqueta: 'Equipo',
                      valor: identificador,
                      llave: const Key('reporte_resumen_equipo'),
                    ),
                    _Fila(
                      icono: Icons.location_on_outlined,
                      etiqueta: 'Ubicación',
                      valor: ubicacion,
                    ),
                    _Fila(
                      icono: Icons.category_outlined,
                      etiqueta: 'Tipo',
                      valor: incidencia.tipo.etiqueta,
                      llave: const Key('reporte_resumen_tipo'),
                    ),
                    _Fila(
                      icono: Icons.flag_outlined,
                      etiqueta: 'Estado',
                      valor: incidencia.estado.etiqueta,
                      llave: const Key('reporte_resumen_estado'),
                      color: Colors.orange,
                    ),
                    _Fila(
                      icono: Icons.access_time,
                      etiqueta: 'Fecha',
                      valor: _formatearFechaHora(incidencia.fechaReporte),
                    ),
                  ]
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: w,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.llave,
    this.color,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final Key? llave;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: color ?? colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$etiqueta: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: valor,
                  style: color != null ? TextStyle(color: color) : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error de envío
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorEnvio extends StatelessWidget {
  const _ErrorEnvio({
    super.key,
    required this.mensaje,
    required this.reintentable,
  });

  final String mensaje;
  final bool reintentable;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ReportarIncidenciaProvider>();
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
              'No se pudo enviar el reporte',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              key: const Key('reporte_error_mensaje'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (reintentable)
              FilledButton.icon(
                key: const Key('reporte_boton_reintentar'),
                onPressed: () => provider.reintentar(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('reporte_boton_volver_formulario'),
              onPressed: provider.volverAlFormulario,
              child: const Text('Editar reporte'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta del equipo identificado
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaEquipo extends StatelessWidget {
  const _TarjetaEquipo({required this.equipo});

  final Equipo equipo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.computer, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipo.identificador,
                    key: const Key('reporte_equipo_identificador'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (equipo.nombreVisible != equipo.identificador)
                    Text(
                      equipo.nombreVisible,
                      style: TextStyle(color: colorScheme.outline),
                    ),
                  Text(
                    equipo.ubicacion,
                    key: const Key('reporte_equipo_ubicacion'),
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades
// ─────────────────────────────────────────────────────────────────────────────

String _formatearFechaHora(DateTime valor) {
  final l = valor.toLocal();
  String d(int n) => n.toString().padLeft(2, '0');
  return '${d(l.day)}/${d(l.month)}/${l.year} ${d(l.hour)}:${d(l.minute)}';
}

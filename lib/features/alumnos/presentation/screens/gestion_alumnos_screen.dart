import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../dominio/alumno.dart';
import '../../domain/repositories/alumnos_repository.dart';
import '../../domain/usecases/cambiar_estado_alumno_usecase.dart';
import '../../domain/usecases/listar_alumnos_usecase.dart';
import '../providers/gestion_alumnos_provider.dart';
import 'registrar_alumno_screen.dart';

/// Pantalla de gestión de cuentas de alumno (HU-AD-12):
/// listado con búsqueda, alta, baja lógica y reactivación.
class GestionAlumnosScreen extends StatelessWidget {
  const GestionAlumnosScreen({
    super.key,
    this.listarUseCase,
    this.cambiarUseCase,
  });

  final ListarAlumnosUseCase? listarUseCase;
  final CambiarEstadoAlumnoUseCase? cambiarUseCase;

  @override
  Widget build(BuildContext context) {
    // El repositorio solo se lee si no se inyectaron los use cases (así la
    // pantalla puede probarse sin el Provider raíz de la app).
    return ChangeNotifierProvider(
      create: (_) => GestionAlumnosProvider(
        listarAlumnosUseCase:
            listarUseCase ??
            ListarAlumnosUseCase(context.read<AlumnosRepository>()),
        cambiarEstadoAlumnoUseCase:
            cambiarUseCase ??
            CambiarEstadoAlumnoUseCase(context.read<AlumnosRepository>()),
      )..cargar(),
      child: const _GestionAlumnosVista(),
    );
  }
}

class _GestionAlumnosVista extends StatefulWidget {
  const _GestionAlumnosVista();

  @override
  State<_GestionAlumnosVista> createState() => _GestionAlumnosVistaState();
}

class _GestionAlumnosVistaState extends State<_GestionAlumnosVista> {
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _registrarAlumno() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegistrarAlumnoScreen()),
    );
    // Al volver del alta se recarga la lista para incluir la cuenta nueva.
    if (!mounted) return;
    await context.read<GestionAlumnosProvider>().cargar(
      busqueda: _busquedaController.text,
    );
  }

  Future<void> _confirmarCambioEstado(Alumno alumno) async {
    final activo = !alumno.activo;
    final provider = context.read<GestionAlumnosProvider>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('cambiar_estado_dialog'),
        title: Text(activo ? 'Reactivar cuenta' : 'Desactivar cuenta'),
        content: Text(
          activo
              ? '${alumno.nombre} volverá a poder iniciar sesión. Sus '
                    'registros anteriores se conservan.'
              : '${alumno.nombre} dejará de poder iniciar sesión, pero su '
                    'cuenta y su historial de uso se conservan.',
        ),
        actions: [
          TextButton(
            key: const Key('cambiar_estado_cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('cambiar_estado_aceptar'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(activo ? 'Reactivar' : 'Desactivar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final ok = await provider.cambiarEstado(alumno, activo: activo);
    if (!ok || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('cambiar_estado_exito'),
        content: Text(
          activo
              ? 'Cuenta de ${alumno.nombre} reactivada.'
              : 'Cuenta de ${alumno.nombre} desactivada. El historial se '
                    'conserva.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GestionAlumnosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar alumnos')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('registrar_alumno_fab'),
        onPressed: _registrarAlumno,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Registrar alumno'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('alumno_busqueda_field'),
              controller: _busquedaController,
              enabled: !provider.isLoading,
              textInputAction: TextInputAction.search,
              onSubmitted: (valor) => provider.buscar(valor),
              decoration: InputDecoration(
                labelText: 'Buscar por nombre, matrícula o correo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  key: const Key('alumno_busqueda_limpiar'),
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busquedaController.clear();
                    provider.buscar('');
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                key: const Key('gestion_alumnos_error'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: _cuerpo(provider)),
        ],
      ),
    );
  }

  Widget _cuerpo(GestionAlumnosProvider provider) {
    if (provider.isLoading && provider.alumnos.isEmpty) {
      return const Center(
        key: Key('gestion_alumnos_loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (provider.status == GestionAlumnosStatus.error &&
        provider.alumnos.isEmpty) {
      return Center(
        key: const Key('gestion_alumnos_vacio_error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudieron cargar las cuentas.'),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('gestion_alumnos_reintentar'),
                onPressed: () => provider.cargar(busqueda: provider.busqueda),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.alumnos.isEmpty) {
      return Center(
        key: const Key('gestion_alumnos_vacio'),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay cuentas de alumno que coincidan con la búsqueda.',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.cargar(busqueda: provider.busqueda),
      child: ListView.separated(
        key: const Key('alumnos_lista'),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.alumnos.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final alumno = provider.alumnos[index];
          return _TileAlumno(
            alumno: alumno,
            ocupado: provider.estaActualizando(alumno),
            alCambiarEstado: () => _confirmarCambioEstado(alumno),
          );
        },
      ),
    );
  }
}

class _TileAlumno extends StatelessWidget {
  const _TileAlumno({
    required this.alumno,
    required this.ocupado,
    required this.alCambiarEstado,
  });

  final Alumno alumno;
  final bool ocupado;
  final VoidCallback alCambiarEstado;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('alumno_${alumno.matricula}'),
      leading: Icon(
        alumno.activo ? Icons.school : Icons.school_outlined,
        color: alumno.activo ? Colors.deepPurple : Colors.grey,
      ),
      title: Text(alumno.nombre),
      subtitle: Text(
        '${alumno.matricula} · ${alumno.correoInstitucional}\n'
        '${alumno.activo ? 'Activa' : 'Desactivada · historial conservado'}',
      ),
      isThreeLine: true,
      trailing: ocupado
          ? const SizedBox(
              key: Key('alumno_actualizando'),
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              key: Key('alumno_estado_${alumno.matricula}'),
              tooltip: alumno.activo ? 'Desactivar cuenta' : 'Reactivar cuenta',
              icon: Icon(
                alumno.activo ? Icons.person_off : Icons.person_outline,
                color: alumno.activo ? Colors.redAccent : Colors.green,
              ),
              onPressed: alCambiarEstado,
            ),
    );
  }
}

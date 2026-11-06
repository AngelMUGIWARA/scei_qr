import 'package:scei_qr/dominio/alta_tecnico.dart';
import 'package:scei_qr/dominio/edicion_tecnico.dart';
import 'package:scei_qr/dominio/tecnico.dart';
import 'package:scei_qr/features/usuarios/domain/repositories/usuarios_repository.dart';

class FakeUsuariosRepository implements UsuariosRepository {
  FakeUsuariosRepository({
    List<Tecnico>? tecnicos,
    this.alRegistrar,
    this.alListar,
    this.alEditar,
    this.alCambiarEstado,
  }) : tecnicos = tecnicos ?? const [];

  List<Tecnico> tecnicos;
  Future<Tecnico> Function(SolicitudAltaTecnico solicitud)? alRegistrar;
  Future<List<Tecnico>> Function(String? busqueda, bool? activo)? alListar;
  Future<Tecnico> Function(int id, SolicitudEdicionTecnico solicitud)? alEditar;
  Future<Tecnico> Function(int id, bool activo)? alCambiarEstado;

  int registrarLlamadas = 0;
  int listarLlamadas = 0;
  int editarLlamadas = 0;
  int cambiarEstadoLlamadas = 0;
  String? ultimaBusqueda;
  bool? ultimoFiltroActivo;
  int? ultimoId;
  SolicitudAltaTecnico? ultimaSolicitudAlta;
  SolicitudEdicionTecnico? ultimaSolicitudEdicion;
  bool? ultimoActivo;

  @override
  Future<Tecnico> registrarTecnico(SolicitudAltaTecnico solicitud) async {
    registrarLlamadas++;
    ultimaSolicitudAlta = solicitud;
    final handler = alRegistrar;
    if (handler != null) return handler(solicitud);
    return tecnicoDePrueba(
      nombreCompleto: solicitud.nombreNormalizado,
      correo: solicitud.correoNormalizado,
      usuario: solicitud.usuarioNormalizado,
    );
  }

  @override
  Future<List<Tecnico>> listarTecnicos({String? busqueda, bool? activo}) async {
    listarLlamadas++;
    ultimaBusqueda = busqueda;
    ultimoFiltroActivo = activo;
    final handler = alListar;
    if (handler != null) return handler(busqueda, activo);

    final porEstado = activo == null
        ? tecnicos
        : tecnicos.where((t) => t.activo == activo).toList(growable: false);
    final termino = busqueda?.toLowerCase();
    if (termino == null || termino.isEmpty) return List.of(porEstado);
    return porEstado
        .where((t) => t.nombreCompleto.toLowerCase().contains(termino))
        .toList(growable: false);
  }

  @override
  Future<Tecnico> editarTecnico(
    int id,
    SolicitudEdicionTecnico solicitud,
  ) async {
    editarLlamadas++;
    ultimoId = id;
    ultimaSolicitudEdicion = solicitud;
    final handler = alEditar;
    if (handler != null) return handler(id, solicitud);

    final actual = _buscar(id);
    final actualizado = Tecnico(
      id: actual.id,
      nombreCompleto: solicitud.nombreNormalizado,
      correo: solicitud.correoNormalizado,
      usuario: actual.usuario,
      activo: actual.activo,
      fechaAlta: actual.fechaAlta,
    );
    _reemplazar(actualizado);
    return actualizado;
  }

  @override
  Future<Tecnico> cambiarEstadoTecnico(int id, {required bool activo}) async {
    cambiarEstadoLlamadas++;
    ultimoId = id;
    ultimoActivo = activo;
    final handler = alCambiarEstado;
    if (handler != null) return handler(id, activo);

    final actual = _buscar(id);
    final actualizado = Tecnico(
      id: actual.id,
      nombreCompleto: actual.nombreCompleto,
      correo: actual.correo,
      usuario: actual.usuario,
      activo: activo,
      fechaAlta: actual.fechaAlta,
    );
    _reemplazar(actualizado);
    return actualizado;
  }

  Tecnico _buscar(int id) =>
      tecnicos.firstWhere((t) => t.id == id, orElse: () => tecnicoDePrueba());

  void _reemplazar(Tecnico actualizado) {
    tecnicos = [
      for (final item in tecnicos)
        item.id == actualizado.id ? actualizado : item,
    ];
  }
}

Tecnico tecnicoDePrueba({
  int id = 7,
  String nombreCompleto = 'Carlos Mena',
  String correo = 'carlos.mena@utez.edu.mx',
  String usuario = 'cmena',
  bool activo = true,
}) {
  return Tecnico(
    id: id,
    nombreCompleto: nombreCompleto,
    correo: correo,
    usuario: usuario,
    activo: activo,
  );
}

List<Tecnico> tecnicosDePrueba() => [
  tecnicoDePrueba(),
  tecnicoDePrueba(
    id: 8,
    nombreCompleto: 'Lucía López',
    correo: 'lucia.lopez@utez.edu.mx',
    usuario: 'llopez',
    activo: false,
  ),
];

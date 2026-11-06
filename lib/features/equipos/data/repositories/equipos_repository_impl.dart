import 'dart:typed_data';

import '../../../../dominio/alta_equipo.dart';
import '../../../../dominio/edicion_equipo.dart';
import '../../../../dominio/equipo.dart';
import '../../domain/repositories/equipos_repository.dart';
import '../datasources/equipos_remote_data_source.dart';

class EquiposRepositoryImpl implements EquiposRepository {
  const EquiposRepositoryImpl(this.remote);

  final EquiposRemoteDataSource remote;

  @override
  Future<Equipo> registrarEquipo(SolicitudAltaEquipo solicitud) async {
    final model = await remote.registrarEquipo(solicitud);
    return model.toEntity();
  }

  @override
  Future<List<Equipo>> listarEquipos({
    String? q,
    String? ubicacion,
    bool? activo,
  }) async {
    final models = await remote.listarEquipos(
      q: q,
      ubicacion: ubicacion,
      activo: activo,
    );
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<Equipo> obtenerEquipoPorId(int id) async {
    final model = await remote.obtenerEquipoPorId(id);
    return model.toEntity();
  }

  @override
  Future<Equipo> actualizarEquipo(
    int id,
    SolicitudEdicionEquipo solicitud,
  ) async {
    final model = await remote.actualizarEquipo(id, solicitud);
    return model.toEntity();
  }

  @override
  Future<Equipo> cambiarEstadoEquipo(int id, {required bool activo}) async {
    final model = await remote.cambiarEstadoEquipo(id, activo: activo);
    return model.toEntity();
  }

  @override
  Future<Equipo> regenerarQr(int id) async {
    final model = await remote.regenerarQr(id);
    return model.toEntity();
  }

  @override
  Future<Uint8List> obtenerImagenQr(int id) => remote.obtenerImagenQr(id);
}

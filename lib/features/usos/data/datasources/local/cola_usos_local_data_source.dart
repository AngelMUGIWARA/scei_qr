import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/uso_pendiente_model.dart';

abstract class ColaUsosLocalDataSource {
  Future<List<UsoPendienteModel>> leer();

  Future<void> guardar(List<UsoPendienteModel> pendientes);
}

/// Persistencia de la cola de usos pendientes en `SharedPreferences`.
///
/// No guarda secretos (solo el token de QR y metadatos del equipo), por lo que
/// no requiere almacenamiento seguro.
class SharedPreferencesColaUsosLocalDataSource
    implements ColaUsosLocalDataSource {
  SharedPreferencesColaUsosLocalDataSource({
    Future<SharedPreferences> Function()? obtenerPrefs,
  }) : _obtenerPrefs = obtenerPrefs ?? SharedPreferences.getInstance;

  static const String _clave = 'usos_pendientes_v1';

  final Future<SharedPreferences> Function() _obtenerPrefs;

  @override
  Future<List<UsoPendienteModel>> leer() async {
    final prefs = await _obtenerPrefs();
    final raw = prefs.getString(_clave);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => UsoPendienteModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      // Datos corruptos: se descartan para no romper el arranque.
      return const [];
    }
  }

  @override
  Future<void> guardar(List<UsoPendienteModel> pendientes) async {
    final prefs = await _obtenerPrefs();
    final raw = jsonEncode(
      pendientes.map((pendiente) => pendiente.toJson()).toList(),
    );
    await prefs.setString(_clave, raw);
  }
}

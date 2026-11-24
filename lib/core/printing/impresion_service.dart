import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Abstracción de las acciones del sistema operativo para que la UI sea
/// testeable sin canales de plataforma.
abstract class ImpresionService {
  /// Abre el diálogo de impresión del sistema.
  Future<void> imprimir(Uint8List pdf, {required String nombre});

  /// Comparte/guarda el PDF (bandeja del sistema en móvil).
  Future<void> descargar(Uint8List pdf, {required String nombre});
}

class PrintingImpresionService implements ImpresionService {
  const PrintingImpresionService();

  @override
  Future<void> imprimir(Uint8List pdf, {required String nombre}) async {
    final enviado = await Printing.layoutPdf(
      name: nombre,
      onLayout: (_) async => pdf,
    );
    if (!enviado) {
      throw StateError('La impresión fue cancelada.');
    }
  }

  @override
  Future<void> descargar(Uint8List pdf, {required String nombre}) async {
    await Printing.sharePdf(bytes: pdf, filename: nombre);
  }
}

/// Convierte un texto legible en un nombre de archivo seguro.
String slugArchivo(String value) {
  const reemplazos = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'Á': 'a',
    'É': 'e',
    'Í': 'i',
    'Ó': 'o',
    'Ú': 'u',
    'Ü': 'u',
    'Ñ': 'n',
  };

  var texto = value.trim().toLowerCase();
  reemplazos.forEach((origen, destino) {
    texto = texto.replaceAll(origen, destino);
  });
  final limpio = texto
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return limpio.isEmpty ? 'equipos' : limpio;
}

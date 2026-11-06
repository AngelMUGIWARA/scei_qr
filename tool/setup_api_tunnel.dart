import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String _apiHealthUrl = 'http://localhost:3000/api/v1/health';
const int _apiPort = 3000;

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);

  if (options.help) {
    _printUsage();
    return;
  }

  final adb = _findAdb(options.adbPath);
  if (adb == null) {
    _fail(
      'No se encontró adb.\n'
      'Instala Android SDK Platform-Tools o define ANDROID_HOME/ANDROID_SDK_ROOT.\n'
      'También puedes indicar la ruta con --adb <ruta>.',
    );
  }

  await _ensureBackend();

  final devices = await _listDevices(adb);
  if (devices.isEmpty) {
    _fail(
      'No hay dispositivos Android conectados.\n'
      'Inicia un emulador o conecta un teléfono por USB y vuelve a ejecutar el script.',
    );
  }

  for (final serial in devices) {
    await _setupReverse(adb, serial);
  }

  if (options.device != null) {
    await _runFlutter(options.device!);
    return;
  }

  stdout.writeln('');
  stdout.writeln('Listo. Ahora ejecuta la app desde el IDE o con:');
  stdout.writeln('  flutter run -d <device-id>');
  stdout.writeln('');
  stdout.writeln(
    'Si desconectas el dispositivo o reinicias adb, vuelve a ejecutar este script.',
  );
}

class _Options {
  const _Options({this.device, this.adbPath, this.help = false});

  final String? device;
  final String? adbPath;
  final bool help;
}

_Options _parseArgs(List<String> args) {
  String? device;
  String? adbPath;
  var help = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];

    if (arg == '--help' || arg == '-h') {
      help = true;
    } else if (arg == '--device') {
      if (i + 1 >= args.length) {
        _fail('Falta el valor de --device.');
      }
      device = args[++i];
    } else if (arg.startsWith('--device=')) {
      device = arg.substring('--device='.length);
    } else if (arg == '--adb') {
      if (i + 1 >= args.length) {
        _fail('Falta el valor de --adb.');
      }
      adbPath = args[++i];
    } else if (arg.startsWith('--adb=')) {
      adbPath = arg.substring('--adb='.length);
    } else {
      _fail('Opción no reconocida: $arg');
    }
  }

  return _Options(device: device, adbPath: adbPath, help: help);
}

String? _findAdb(String? overridePath) {
  if (overridePath != null && overridePath.trim().isNotEmpty) {
    final path = overridePath.trim();
    return File(path).existsSync() ? path : null;
  }

  final environment = Platform.environment;
  final candidates = <String>[];

  void addSdkRoot(String? root) {
    if (root == null || root.trim().isEmpty) {
      return;
    }
    candidates.add(
      Platform.isWindows
          ? '$root\\platform-tools\\adb.exe'
          : '$root/platform-tools/adb',
    );
  }

  addSdkRoot(environment['ANDROID_HOME']);
  addSdkRoot(environment['ANDROID_SDK_ROOT']);

  final home = environment['HOME'];
  if (Platform.isWindows) {
    final localAppData = environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      candidates.add('$localAppData\\Android\\Sdk\\platform-tools\\adb.exe');
    }
  } else if (Platform.isMacOS) {
    if (home != null && home.isNotEmpty) {
      candidates.add('$home/Library/Android/sdk/platform-tools/adb');
    }
  } else if (Platform.isLinux) {
    if (home != null && home.isNotEmpty) {
      candidates.add('$home/Android/Sdk/platform-tools/adb');
    }
  }

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  final executable = Platform.isWindows ? 'adb.exe' : 'adb';
  try {
    final result = Process.runSync(executable, const [
      'version',
    ], runInShell: true);
    if (result.exitCode == 0) {
      return executable;
    }
  } on ProcessException {
    // adb no está en PATH.
  }

  return null;
}

Future<void> _ensureBackend() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

  try {
    final request = await client
        .getUrl(Uri.parse(_apiHealthUrl))
        .timeout(const Duration(seconds: 5));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close().timeout(const Duration(seconds: 5));
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != HttpStatus.ok) {
      _fail(
        'El backend respondió ${response.statusCode} en $_apiHealthUrl.\n'
        '$body',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'ok') {
      _fail('Respuesta inesperada del backend: $body');
    }

    stdout.writeln('OK: backend disponible en $_apiHealthUrl');
  } on TimeoutException {
    _fail(
      'El backend no respondió a tiempo en $_apiHealthUrl.\n'
      'Inicia el backend con: docker compose up -d',
    );
  } on SocketException catch (error) {
    _fail(
      'No se pudo conectar al backend en $_apiHealthUrl.\n'
      '$error\n'
      'Inicia el backend con: docker compose up -d',
    );
  } on FormatException {
    _fail('Respuesta inválida del backend en $_apiHealthUrl.');
  } finally {
    client.close(force: true);
  }
}

Future<List<String>> _listDevices(String adb) async {
  final result = await Process.run(adb, const ['devices']);
  if (result.exitCode != 0) {
    _fail(
      'adb devices falló.\n'
      '${result.stderr}\n'
      '${result.stdout}',
    );
  }

  final devices = <String>[];
  final lines = (result.stdout as String).split(RegExp(r'\r?\n'));

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('List of devices')) {
      continue;
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      continue;
    }

    final serial = parts[0];
    final state = parts[1];

    if (state == 'device') {
      devices.add(serial);
    } else if (state == 'unauthorized') {
      stderr.writeln(
        'ADVERTENCIA: $serial no está autorizado. '
        'Acepta el diálogo de depuración USB en el teléfono.',
      );
    } else if (state == 'offline') {
      stderr.writeln('ADVERTENCIA: $serial está offline. Reconéctalo.');
    }
  }

  return devices;
}

Future<void> _setupReverse(String adb, String serial) async {
  final result = await Process.run(adb, [
    '-s',
    serial,
    'reverse',
    'tcp:$_apiPort',
    'tcp:$_apiPort',
  ]);

  if (result.exitCode != 0) {
    _fail(
      'No se pudo configurar adb reverse para $serial.\n'
      '${result.stderr}\n'
      '${result.stdout}',
    );
  }

  final output = (result.stdout as String).trim();
  final suffix = output.isEmpty ? '' : ' ($output)';
  stdout.writeln('OK: $serial -> localhost:$_apiPort$suffix');
}

Future<void> _runFlutter(String device) async {
  stdout.writeln('');
  stdout.writeln('Ejecutando flutter run -d $device ...');

  try {
    final process = await Process.start(
      'flutter',
      ['run', '-d', device],
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      exit(exitCode);
    }
  } on ProcessException catch (error) {
    _fail('No se pudo ejecutar flutter: ${error.message}');
  }
}

void _printUsage() {
  stdout.writeln('''
Configura adb reverse para conectar la app Android con el backend local.

Uso:
  dart run tool/setup_api_tunnel.dart [opciones]

Opciones:
  --device <id>   Después de configurar el túnel, ejecuta flutter run -d <id>.
  --adb <ruta>    Ruta explícita al ejecutable adb.
  -h, --help      Muestra esta ayuda.

Requisitos:
  - Backend disponible en $_apiHealthUrl.
  - Emulador Android iniciado o dispositivo Android conectado por USB.
''');
}

Never _fail(String message) {
  stderr.writeln('');
  stderr.writeln('ERROR: $message');
  exit(1);
}

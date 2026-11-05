import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';

import 'package:scei_qr/core/storage/secure_storage_service.dart';

class FailingDeletePlatform extends TestFlutterSecureStoragePlatform {
  FailingDeletePlatform(super.data);

  final List<String> attemptedDeletes = [];
  String? failOnKey;

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    attemptedDeletes.add(key);

    if (key == failOnKey) {
      throw Exception('Error simulado al eliminar $key');
    }

    await super.delete(key: key, options: options);
  }
}

void main() {
  late FailingDeletePlatform platform;
  late FlutterSecureStoragePlatform originalPlatform;
  late SecureStorageService service;

  setUp(() {
    originalPlatform = FlutterSecureStoragePlatform.instance;

    platform = FailingDeletePlatform({
      'auth_session': 'sesion',
      'auth_token': 'token',
      'auth_user': 'usuario',
    });

    FlutterSecureStoragePlatform.instance = platform;

    service = SecureStorageService(storage: const FlutterSecureStorage());
  });

  tearDown(() {
    FlutterSecureStoragePlatform.instance = originalPlatform;
  });

  group('SecureStorageService.readAccessToken', () {
    test('lee el token de la sesión unificada', () async {
      platform.data['auth_session'] = jsonEncode({
        'token': 'jwt-unificado',
        'user': '{}',
      });

      expect(await service.readAccessToken(), 'jwt-unificado');
    });

    test('usa el token legacy si no hay sesión unificada', () async {
      platform.data.remove('auth_session');
      platform.data['auth_token'] = 'jwt-legacy';

      expect(await service.readAccessToken(), 'jwt-legacy');
    });

    test('devuelve null si no hay token', () async {
      platform.data.remove('auth_session');
      platform.data.remove('auth_token');

      expect(await service.readAccessToken(), isNull);
    });
  });

  group('SecureStorageService.clear', () {
    test(
      'intenta eliminar todas las claves aunque falle una eliminación',
      () async {
        platform.failOnKey = 'auth_token';

        await expectLater(service.clear(), throwsA(isA<Exception>()));

        expect(platform.attemptedDeletes, [
          'auth_session',
          'auth_token',
          'auth_user',
        ]);

        expect(platform.data.containsKey('auth_session'), isFalse);
        expect(platform.data.containsKey('auth_token'), isTrue);
        expect(platform.data.containsKey('auth_user'), isFalse);
      },
    );
  });

  group('SecureStorageService.clearLegacySession', () {
    test(
      'intenta eliminar el usuario aunque falle la eliminación del token',
      () async {
        platform.failOnKey = 'auth_token';

        await expectLater(
          service.clearLegacySession(),
          throwsA(isA<Exception>()),
        );

        expect(platform.attemptedDeletes, ['auth_token', 'auth_user']);

        expect(platform.data.containsKey('auth_token'), isTrue);
        expect(platform.data.containsKey('auth_user'), isFalse);
      },
    );
  });
}

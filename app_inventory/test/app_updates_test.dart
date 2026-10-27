import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_inventory/core/api.dart';
import 'package:app_inventory/core/app_updates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final valid = {
    'available': true,
    'version': '1.0.1',
    'build_number': 4,
    'apk_path': '/releases/sims-1.0.1-4.apk',
    'sha256': 'a' * 64,
    'size_bytes': 1024,
    'notes': 'Perbaikan.',
  };
  test(
    'APK metadata cannot redirect the app to an unrelated or unverified installer',
    () {
      expect(
        AppRelease.parse(
          valid,
          Uri.parse('https://sims.example'),
          false,
        )!.url.toString(),
        'https://sims.example/releases/sims-1.0.1-4.apk',
      );
      for (final patch in [
        {'apk_path': 'https://evil.example/a.apk'},
        {'apk_path': '/releases/../a.apk'},
        {'apk_path': '/releases/a.apk?token=secret'},
        {'sha256': 'invalid'},
        {'size_bytes': 0},
        {'size_bytes': 151 * 1024 * 1024},
      ]) {
        expect(
          () => AppRelease.parse(
            {...valid, ...patch},
            Uri.parse('https://sims.example'),
            false,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => AppRelease.parse(valid, Uri.parse('http://sims.example'), false),
        throwsFormatException,
      );
      expect(
        AppRelease.parse(
          {'available': false},
          Uri.parse('https://sims.example'),
          false,
        ),
        isNull,
      );
    },
  );
  test(
    'Version checks preserve query strings, do not send login tokens, and ignore old builds',
    () async {
      final api = ApiClient(
        baseUrl: 'https://sims.example',
        client: MockClient((request) async {
          expect(request.url.path, '/api/mobile/releases/');
          expect(request.url.queryParameters['platform'], 'web');
          expect(request.headers.containsKey('authorization'), isFalse);
          return http.Response(jsonEncode(valid), 200);
        }),
      )..token = 'private-session-token';
      final updates = AppUpdates(
        api,
        webOverride: true,
        currentBuildOverride: 4,
      );
      await updates.check();
      expect(updates.available, isFalse);
      expect(updates.error, isNull);
      updates.dispose();
      api.close();
    },
  );
  test(
    'New Android releases are downloaded with all verification constraints and installed only afterwards',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppUpdates.channel, (call) async {
            calls.add(call);
            if (call.method == 'downloadUpdate') return true;
            if (call.method == 'installUpdate') return 'permission_required';
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AppUpdates.channel, null),
      );
      final api = ApiClient(
        baseUrl: 'https://sims.example',
        client: MockClient((_) async => http.Response(jsonEncode(valid), 200)),
      );
      final updates = AppUpdates(
        api,
        webOverride: false,
        currentBuildOverride: 3,
      );
      await updates.check();
      expect(updates.available, isTrue);
      expect(await updates.install(), 'failed');
      expect(calls, isEmpty);
      await updates.download();
      expect(updates.downloaded, isTrue);
      expect(calls.first.arguments, containsPair('sha256', 'a' * 64));
      expect(calls.first.arguments, containsPair('size_bytes', 1024));
      expect(
        calls.first.arguments,
        containsPair('origin', 'https://sims.example'),
      );
      expect(await updates.install(), 'permission_required');
      updates.dispose();
      api.close();
    },
  );
  test(
    'Failed checksum or signature verification never offers installation',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppUpdates.channel, (call) async {
            throw PlatformException(
              code: 'UPDATE_REJECTED',
              message: 'Paket ditolak.',
            );
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AppUpdates.channel, null),
      );
      final api = ApiClient(
        baseUrl: 'https://sims.example',
        client: MockClient((_) async => http.Response(jsonEncode(valid), 200)),
      );
      final updates = AppUpdates(
        api,
        webOverride: false,
        currentBuildOverride: 3,
      );
      await updates.check();
      await updates.download();
      expect(updates.downloaded, isFalse);
      expect(updates.error, 'Paket ditolak.');
      updates.dispose();
      api.close();
    },
  );
}

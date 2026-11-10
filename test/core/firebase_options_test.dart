import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/firebase_options.dart';

void main() {
  test('Android Firebase options match the package selected by Gradle', () {
    const package = String.fromEnvironment('APP_ENV') == 'staging'
        ? 'com.sparkbytekh.tilomnov.staging'
        : 'com.sparkbytekh.tilomnov';
    final config =
        jsonDecode(File('android/app/google-services.json').readAsStringSync())
            as Map<String, dynamic>;
    final client = (config['client'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere(
          (client) =>
              client['client_info']['android_client_info']['package_name'] ==
              package,
        );
    expect(
      DefaultFirebaseOptions.android.appId,
      client['client_info']['mobilesdk_app_id'],
    );
    expect(
      DefaultFirebaseOptions.android.projectId,
      config['project_info']['project_id'],
    );
    expect(
      DefaultFirebaseOptions.android.apiKey,
      client['api_key'][0]['current_key'],
    );
  });
}

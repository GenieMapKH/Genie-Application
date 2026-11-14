import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release builds never fall back to the debug signing key', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final release = gradle.substring(gradle.indexOf('    buildTypes {'));
    expect(release, isNot(contains('getByName("debug")')));
    expect(
      gradle,
      contains('throw GradleException("Release signing is required.'),
    );
  });
}

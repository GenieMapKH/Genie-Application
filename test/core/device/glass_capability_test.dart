import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/device/glass_capability.dart';

void main() {
  test('the iOS major version is read from the system version', () {
    expect(majorVersionOf('26.0.1'), 26);
    expect(majorVersionOf('18.5'), 18);
    expect(majorVersionOf('26'), 26);
    expect(majorVersionOf(''), isNull);
    expect(majorVersionOf('beta'), isNull);
  });

  test('HyperOS builds give their major version; MIUI and others none', () {
    expect(hyperOsMajorVersionOf('OS3.0.4.0.WOCMIXM'), 3);
    expect(hyperOsMajorVersionOf('OS4.0.0.7.XOCMIXM'), 4);
    expect(hyperOsMajorVersionOf('OS1.0.12.0.UMLMIXM'), 1);
    expect(hyperOsMajorVersionOf('V14.0.5.0.TKHMIXM'), isNull);
    expect(hyperOsMajorVersionOf('S918BXXU3BWK5'), isNull);
    expect(hyperOsMajorVersionOf(''), isNull);
  });

  test('Xiaomi, Redmi and POCO count as one family, in any case', () {
    expect(isXiaomiFamily('Xiaomi', 'Redmi'), isTrue);
    expect(isXiaomiFamily('Xiaomi', 'POCO'), isTrue);
    expect(isXiaomiFamily('', 'redmi'), isTrue);
    expect(isXiaomiFamily('samsung', 'samsung'), isFalse);
    expect(isXiaomiFamily('Google', 'google'), isFalse);
  });
}

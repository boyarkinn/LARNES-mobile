import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/navigation/legal_web_url.dart';

void main() {
  test('buildLegalHubUrl uses locale segment', () {
    expect(
      buildLegalHubUrl(locale: 'ru'),
      endsWith('/ru/legal'),
    );
    expect(
      buildLegalHubUrl(locale: 'en'),
      endsWith('/en/legal'),
    );
  });

  test('buildAppWebUrl joins base and path', () {
    expect(
      buildAppWebUrl('/ru/legal/terms?version=abc'),
      endsWith('/ru/legal/terms?version=abc'),
    );
  });
}

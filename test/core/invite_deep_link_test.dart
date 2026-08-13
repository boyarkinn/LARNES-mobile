import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/deep_links/invite_deep_link.dart';

void main() {
  test('maps locale invite adult-claim URL', () {
    final path = mapInviteUriToAppPath(
      Uri.parse('https://larnes.ru/ru/invite/family-adult-claim?token=abc'),
    );
    expect(path, '/invite/family-adult-claim?token=abc');
  });

  test('maps legacy preaccount-claim to adult-claim', () {
    final path = mapInviteUriToAppPath(
      Uri.parse('https://larnes.ru/invite/preaccount-claim?token=xyz'),
    );
    expect(path, '/invite/family-adult-claim?token=xyz');
  });

  test('ignores unrelated paths', () {
    expect(mapInviteUriToAppPath(Uri.parse('https://larnes.ru/parent')), isNull);
  });
}

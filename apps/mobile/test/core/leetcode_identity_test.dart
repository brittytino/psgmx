import 'package:flutter_test/flutter_test.dart';
import 'package:psgmx_mobile/core/leetcode_identity.dart';

void main() {
  test('accepts a LeetCode username entered in the app', () {
    expect(LeetCodeIdentity.requireValid('naresh_703'), 'naresh_703');
  });

  test('extracts username from a LeetCode profile URL', () {
    expect(
      LeetCodeIdentity.requireValid('https://leetcode.com/u/naresh-703/'),
      'naresh-703',
    );
  });

  test('rejects values that cannot be LeetCode identities', () {
    expect(
      () => LeetCodeIdentity.requireValid('not a username'),
      throwsFormatException,
    );
  });
}

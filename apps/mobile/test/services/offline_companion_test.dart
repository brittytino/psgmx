import 'package:flutter_test/flutter_test.dart';
import 'package:psgmx_mobile/services/offline_companion.dart';

void main() {
  test('provides useful DSA guidance without claiming live personal data', () {
    final answer = OfflineCompanion.answer(
      'Give me a DSA study plan',
      context: const OfflineCompanionContext(
        firstName: 'Anu',
        batchCode: '26MX',
      ),
    );

    expect(answer, contains('Offline companion'));
    expect(answer, contains('two pointers'));
    expect(answer, contains('Reconnect'));
    expect(answer, isNot(contains('trouble connecting')));
  });

  test('protects live placement facts while still giving a reasoning path', () {
    final answer = OfflineCompanion.answer('Which company is hiring today?');

    expect(answer, contains('will not invent live placement details'));
    expect(answer, contains('what is known'));
  });
}

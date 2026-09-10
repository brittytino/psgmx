import 'package:flutter_test/flutter_test.dart';
import 'package:psgmx_mobile/providers/navigation_provider.dart';

void main() {
  test('navigation always exposes a valid companion tab', () {
    final navigation = NavigationProvider();

    navigation.setIndex(99);
    expect(
      navigation.currentIndex,
      NavigationProvider.destinationCount - 1,
    );

    navigation.setIndex(-4);
    expect(navigation.currentIndex, 0);
  });

  test('selecting the current tab does not notify listeners', () {
    final navigation = NavigationProvider();
    var notifications = 0;
    navigation.addListener(() => notifications++);

    navigation.setIndex(0);
    expect(notifications, 0);

    navigation.setIndex(1);
    expect(notifications, 1);
  });
}

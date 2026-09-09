import 'package:flutter_test/flutter_test.dart';
import 'package:psgmx_mobile/models/app_user.dart';

void main() {
  test('26MX pending onboarding follows junior experience', () {
    final user = AppUser.fromMap({
      'id': 'student-id',
      'email': 'student@example.com',
      'reg_no': '26MX001',
      'name': 'Student',
      'batch': 'G1',
      'roles': {'isStudent': true},
      'batches': {'status': 'pending_onboarding'},
    });
    expect(user.isActiveJunior, isTrue);
    expect(user.isActiveSenior, isFalse);
  });

  test('25MX active senior receives placement-log experience', () {
    final user = AppUser.fromMap({
      'id': 'student-id',
      'email': 'student@psgtech.ac.in',
      'reg_no': '25MX001',
      'name': 'Student',
      'batch': 'G1',
      'roles': {'isStudent': true},
      'batches': {'status': 'active_senior'},
    });
    expect(user.isActiveSenior, isTrue);
    expect(user.isActiveJunior, isFalse);
  });

  test('connected GitHub profile survives profile hydration', () {
    final user = AppUser.fromMap({
      'id': 'student-id',
      'email': 'student@example.com',
      'reg_no': '25MX001',
      'name': 'Student',
      'batch': 'G1',
      'roles': {'isStudent': true},
      'github_url': 'https://github.com/psgmx-student',
      'batches': {'status': 'active_senior'},
    });

    expect(user.githubUrl, 'https://github.com/psgmx-student');
    expect(user.toMap()['github_url'], 'https://github.com/psgmx-student');
  });
}
